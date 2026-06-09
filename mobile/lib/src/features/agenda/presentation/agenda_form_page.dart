import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/agenda/data/agenda_repository.dart';
import 'package:smartfridge_mobile/src/features/agenda/presentation/agenda_controller.dart';

class AgendaFormPage extends ConsumerStatefulWidget {
  const AgendaFormPage({
    super.key,
    this.initialEvent,
    this.initialDate,
  });

  final AgendaEventModel? initialEvent;
  final DateTime? initialDate;

  @override
  ConsumerState<AgendaFormPage> createState() => _AgendaFormPageState();
}

class _AgendaFormPageState extends ConsumerState<AgendaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _startAt;
  late DateTime _endAt;
  AgendaEventStatus _status = AgendaEventStatus.scheduled;
  bool _loading = false;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;

    if (initialEvent != null) {
      _titleController.text = initialEvent.title;
      _descriptionController.text = initialEvent.description;
      _startAt = initialEvent.startAt;
      _endAt = initialEvent.endAt;
      _status = initialEvent.status;
      return;
    }

    final baseDate = widget.initialDate ?? DateTime.now();
    _startAt = DateTime(baseDate.year, baseDate.month, baseDate.day, 9);
    _endAt = DateTime(baseDate.year, baseDate.month, baseDate.day, 10);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String _timeLabel(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _startAt.hour,
        _startAt.minute,
      );
      _endAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _endAt.hour,
        _endAt.minute,
      );
      if (_endAt.isBefore(_startAt)) {
        _endAt = _startAt.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final source = isStart ? _startAt : _endAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: source.hour, minute: source.minute),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      final next = DateTime(
        source.year,
        source.month,
        source.day,
        picked.hour,
        picked.minute,
      );

      if (isStart) {
        _startAt = next;
        if (_endAt.isBefore(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      } else {
        _endAt = next;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endAt.isBefore(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('O horario final nao pode ser antes do horario inicial.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final repository = ref.read(agendaRepositoryProvider);

    try {
      if (_isEditing) {
        await repository.update(
          id: widget.initialEvent!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startAt: _startAt,
          endAt: _endAt,
          status: _status,
        );
      } else {
        await repository.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startAt: _startAt,
          endAt: _endAt,
          status: _status,
        );
      }

      invalidateAgendaProviders(ref);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Evento atualizado com sucesso.'
                : 'Evento criado com sucesso.',
          ),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete() async {
    final event = widget.initialEvent;
    if (event == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir evento'),
              content: const Text('Deseja remover este evento da Agenda?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(agendaRepositoryProvider).delete(event.id);
      invalidateAgendaProviders(ref);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluido com sucesso.')),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Evento' : 'Novo Evento'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Voltar ao inicio',
        ),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _loading ? null : _delete,
              tooltip: 'Excluir evento',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titulo'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o titulo';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descricao',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            _DateTimeTile(
              label: 'Data',
              value: _dateLabel(_startAt),
              icon: Icons.calendar_month_outlined,
              onTap: _loading ? null : _pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    label: 'Inicio',
                    value: _timeLabel(_startAt),
                    icon: Icons.schedule_outlined,
                    onTap: _loading ? null : () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeTile(
                    label: 'Fim',
                    value: _timeLabel(_endAt),
                    icon: Icons.timer_outlined,
                    onTap: _loading ? null : () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AgendaEventStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: AgendaEventStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _status = value);
                    },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
        ),
        child: Text(value),
      ),
    );
  }
}

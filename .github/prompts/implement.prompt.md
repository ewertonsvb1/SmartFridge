# Implement Prompt

Implemente a mudanca seguindo os padroes reais do projeto SmartFridge.

## Instrucao principal

Antes de codar, leia:

- `.ai/core/architecture.md`
- `.ai/core/conventions.md`
- `.ai/core/patterns.md`
- contextos modulares aplicaveis em `.ai/context/`

## Regras de implementacao

- No backend, preserve o padrao `Controller -> Service -> Repository -> Mapper -> dto`.
- Use `AuthenticatedUserService` quando a regra depender do usuario atual.
- Mantenha validacao de payload em DTOs e regra de negocio no service.
- No app Flutter, reuse repositorios `Dio`, providers Riverpod e rotas do `GoRouter`.
- Apos mutacoes no app, invalide providers afetados em vez de sincronizar estado manualmente.
- Nao introduza abstrações novas sem necessidade clara no codigo atual.

## Saida esperada

- alteracao pronta no codigo
- arquivos de teste quando o risco justificar
- breve nota explicando quais referencias do projeto foram seguidas

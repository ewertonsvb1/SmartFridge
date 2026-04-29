# Refactor Prompt

Refatore com seguranca, preservando comportamento e contratos do projeto atual.

## Antes de comecar

Leia os arquivos em `.ai/core/` e o contexto do modulo impactado.

## Regras

- Preserve endpoints, payloads e providers publicos salvo pedido explicito.
- Mantenha ownership por usuario nas consultas de negocio.
- Nao mova regras do service para o controller.
- Nao troque mapper manual por ferramenta automatica sem razao forte.
- No Flutter, preserve fluxo de autenticacao por `AuthSession` e `GoRouter`.
- Prefira refatoracoes locais por modulo.

## Verificacao

- backend: revisar impacto em testes de auth, seguranca e produto
- mobile: revisar compilacao dos imports e providers invalidados

# Analyze Prompt

Analise o codigo existente antes de propor qualquer alteracao.

## Checklist

1. Leia `.ai/core/architecture.md`, `.ai/core/conventions.md` e `.ai/core/patterns.md`.
2. Leia os contextos modulares relevantes em `.ai/context/`.
3. Identifique quais classes Spring Boot ou features Flutter ja resolvem problema parecido.
4. Liste contratos existentes que nao podem ser quebrados:
   - endpoints
   - DTOs
   - providers Riverpod
   - fluxo de autenticacao JWT
5. Cite arquivos reais do projeto que servem como referencia.

## Saida esperada

- resumo da area impactada
- padroes existentes a reaproveitar
- riscos de regressao
- estrategia minima de implementacao

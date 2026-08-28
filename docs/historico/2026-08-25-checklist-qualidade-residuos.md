# Specification Quality Checklist: Resíduos e Conformidade Documental

**Purpose**: Validar completude e qualidade da spec antes de planejar
**Created**: 2026-08-25
**Feature**: [013-residuos-conformidade.md](../regras/013-residuos-conformidade.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — *com ressalva
      registrada nas Notas*
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification — *ver Notas*

## Gates específicos deste projeto

- [ ] **Princípio VI** (valor operacional): o módulo passa pelo critério —
      economiza tempo e melhora decisão de custo. **Verificado.**
- [ ] **Princípio III** (contrato de módulos): exige **emenda à constituição**
      para a 16ª ModuleKey. **Não feito — gate humano, decisão do Arthur.**
- [x] **D-R2 e D-R3 resolvidas em 25/08** pelo Arthur: nada a divulgar antes de
      construir; e a ordem é **financeiro primeiro, resíduos logo depois**.
- [ ] **D-R1**: em qual plano entra, e quais outros diferenciais entram junto
      para que o plano superior se sustente. Levada ao grupo em 25/08 com os
      números da pesquisa de precificação. **Único bloqueio comercial restante
      para `/speckit-plan`.**
- [ ] Dívida de `storage.objects` (filtro por `bucket_id`) resolvida —
      **bloqueio técnico**, primeiro módulo com upload de arquivo da clínica.

## Notes

**Ressalva sobre "no implementation details".** A spec cita RLS, `clinic_id`,
ModuleKey e a cascata de permissão. Num projeto genérico isso seria vazamento
de implementação para dentro da spec. Aqui não é: os Princípios I e III da
constituição do NexClin tornam essas garantias **requisito de produto**, e uma
spec que as omitisse deixaria de descrever o que o sistema precisa garantir.
A ressalva fica registrada em vez de escondida.

**Itens em aberto bloqueiam a próxima fase.** Os quatro gates específicos deste
projeto são pré-condição para `/speckit-plan`. Três são decisão humana
(constituição + comercial), um é dívida técnica já registrada no handoff de
20/08.

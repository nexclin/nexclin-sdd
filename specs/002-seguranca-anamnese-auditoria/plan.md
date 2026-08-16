# Implementation Plan: Segurança — anamnese pública e auditoria de dado de paciente

**Branch**: `pr30` (spec sem branch própria) | **Date**: 2026-08-16 | **Spec**: [spec.md](spec.md)

**Input**: `specs/002-seguranca-anamnese-auditoria/spec.md`

## Summary

Fechar duas exposições de dado de saúde na plataforma que lança em 01/09:
(1) anon lê/adultera anamnese de qualquer clínica via `USING(true)` — trocar por
token de uso único servido por edge function; (2) ação sobre `patients` não deixa
rastro — adicionar `data_audit_log` + trigger + soft delete. Alvo primário é o
banco Lovable ao vivo; as mesmas correções são backportadas como migrações neste
repositório para a stack nova nascer limpa.

## Technical Context

**Language/Version**: SQL (Postgres 15, migrações Supabase) · TypeScript (Deno, edge function) · React/Next (front do formulário público)

**Primary Dependencies**: Supabase (Postgres + Auth + RLS + Edge Functions) · Resend (não usado nesta spec) · `gen_random_uuid()`

**Storage**: Postgres — **dois projetos**: Lovable ao vivo (`xbnffervqqphgsyeffdz`, alvo primário) e stack nova (`supabase/migrations` deste repo, backport)

**Testing**: aceite manual por Arthur (Princípio IV) · hook `guarda-constituicao` nas migrações · agente `auditor-multitenant` na edge function e triggers

**Target Platform**: plataforma Lovable ao vivo (lança 01/09) → backport para a stack nova (sem prazo)

**Project Type**: correção de segurança — policies de RLS + edge function + triggers de auditoria; não é feature de produto

**Constraints**: o formulário público de anamnese não pode quebrar (paciente preenche sem login); nenhum acesso anônimo direto à tabela pode permanecer; nenhuma credencial em código; sem PITR no tier atual → backup exportado antes de qualquer escrita

**Scale/Scope**: 2 tabelas (`anamnesis_responses`, `anamnesis_config`) + 1 tabela nova (`data_audit_log`) + 1 edge function + 1 trigger em `patients`; ~16 clínicas de teste no banco ao vivo

## Constitution Check

*GATE: passa antes da Fase 0. Reavaliar após o design.*

Esta spec **existe para fazer cumprir** a constituição — não há tensão, há reforço:

- **Princípio I (segurança no banco / default deny):** o `USING(true)` anônimo é a
  violação exata; a correção restaura default deny removendo acesso direto e
  passando por edge function com service role. ✅ alinhado.
- **Princípio II (LGPD / auditoria / senha):** o Achado 2 é a lacuna de auditoria
  que o Princípio II proíbe; a spec a fecha. Nenhuma action define senha. ✅
- **Princípio V (segredo / TS estrito / testes):** service role só na edge
  function (nunca no bundle); guards testados. ✅
- **Princípio VI (valor operacional):** proteger dado de saúde antes de receber
  pagante é pré-condição de operar, não feature. ✅

**Resultado do gate: PASSA.** Zero violação a justificar; `Complexity Tracking` fica vazio.

## Project Structure

### Documentation (this feature)

```text
specs/002-seguranca-anamnese-auditoria/
├── spec.md              # o quê e por quê (já existe)
├── plan.md              # este arquivo
├── research.md          # 3 decisões de design (Fase 0)
├── data-model.md        # deltas de schema
├── contracts/
│   └── anamnesis-publica.md   # contrato da edge function por token
└── quickstart.md        # cenários de validação executáveis
```

### Source Code (onde a correção mora)

```text
# ALVO PRIMÁRIO — plataforma Lovable ao vivo (via git sync do repo
# nexclin-lovable, ou chat Lovable se a Verificação A falhar)
#   - migração: public_token + data_audit_log + deleted_at + drop policies anon
#   - edge function: anamnesis-publica (GET por token, POST submit)
#   - front: /anamnese-publica/:token consumindo a edge function

# BACKPORT — esta stack (nasce limpa)
supabase/
├── migrations/
│   └── <timestamp>_seguranca_anamnese_token.sql
│   └── <timestamp>_auditoria_patients_soft_delete.sql
└── functions/
    └── anamnesis-publica/index.ts
```

**Structure Decision**: a correção é primariamente de banco (policies + triggers)
e de edge function — não de front. O front muda só para trocar `:id` por `:token`.
A stack nova recebe as mesmas mudanças como migrações versionadas, validadas pelo
hook `guarda-constituicao`.

## A ordem manda: Fase 0 é gate absoluto

O design abaixo (research, data-model, contracts) descreve o **alvo correto**.
Mas nada se aplica antes da **Fase 0 da spec** confirmar, com as duas queries de
leitura, que os achados continuam vivos no banco Lovable. Se o scanner do Lovable
já os corrigiu de outra forma, o design se ajusta ou a spec encerra. Projetar
migração para uma policy que talvez já não exista é desperdício — por isso o gate.

## Complexity Tracking

*Vazio — Constitution Check passou sem violações.*

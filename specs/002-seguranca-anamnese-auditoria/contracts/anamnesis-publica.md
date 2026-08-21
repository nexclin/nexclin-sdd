# Contrato — Edge Function `anamnesis-publica`

Substitui o acesso anônimo direto à tabela. É o **único** caminho pelo qual um
não-autenticado toca em `anamnesis_responses`. Roda com service role; valida o
token; nunca expõe mais que a linha daquele token.

## `GET /anamnesis-publica?token=<uuid>`

Carrega o formulário para o paciente preencher.

**Entrada:** `token` (query param) — o `public_token` da resposta.

**Regras:**
- Token inexistente → `404`.
- Resposta com `status = 'preenchido'` → `410 Gone` (token já consumido).
- Sucesso → devolve **apenas**: os campos do formulário (de `anamnesis_config`) e
  os valores já salvos daquela resposta. **Nunca** `patient_id`, `clinic_id`, nem
  qualquer dado de outra linha.

**Saída (200):**
```json
{
  "config": { "campos": [ /* definição do formulário */ ] },
  "responses": { /* respostas parciais já salvas, se houver */ },
  "status": "pendente"
}
```

## `POST /anamnesis-publica?token=<uuid>`

Grava a submissão do paciente.

**Entrada:** `token` (query) + corpo `{ "responses": { ... } }`.

**Regras:**
- Token inexistente → `404`.
- `status = 'preenchido'` → `410` (não reabre, não sobrescreve).
- Sucesso → grava `responses`, marca `status = 'preenchido'`, invalida o token.
  Idempotente contra reenvio: segundo POST no mesmo token → `410`.

**Saída (200):** `{ "ok": true }`

## Invariantes de segurança (o que o `auditor-multitenant` verifica)

1. Sem token válido, nada é lido ou escrito.
2. Um token só alcança a própria linha — impossível enumerar ou ler outra clínica.
3. Nenhuma policy `anon` permanece nas tabelas de anamnese.
4. A service role vive só na edge function (variável de ambiente), nunca no bundle.
5. Token consumido (`preenchido`) é inerte — sem leitura, sem reescrita.

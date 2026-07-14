# MX PERDCOMP — Controle de créditos e compensações

Sistema para enxergar com clareza **quanto de crédito ainda dá para usar no PER/DCOMP**,
substituindo a planilha `CONTROLE DE COMPENSAÇÕES DF CAMPOS.xlsx` (importada em
14/07/2026, aba COMPENSAÇÕES — a mais completa, com eventos até 22/06/2026).

## O problema que resolve
O crédito federal é consumido em **cadeia**: cada DCOMP usa parte do crédito e o que sobra
gera um **novo número resultante**, que vira o inicial da próxima compensação. Como a **Folha**
e o **Fiscal** puxam do mesmo crédito em momentos diferentes, a planilha compartilhada gerava
desencontro. Aqui há **um único saldo vivo** e a **trilha de quem usou o quê**.

## Arquivos
| Arquivo | Para quê |
|---|---|
| `index.html` | O app. Abra no navegador — já vem com os dados da DF CAMPOS (modo local). |
| `schema.sql` | Cria as tabelas no Supabase (modo compartilhado). |
| `seed-df-campos.sql` | Popula o Supabase com os dados da DF CAMPOS. Rode **depois** do schema. |
| `seed-df-campos.json` | Mesmos dados em JSON (fonte da carga embutida no app). |

## Modo local (imediato)
Abra `index.html`. Funciona 100% offline, salvando em `localStorage` deste navegador.
Bom para validar. **Não** resolve o desencontro sozinho (cada um teria sua cópia).

## Modo compartilhado (a correção de verdade)
1. No Supabase, rode `schema.sql` e depois `seed-df-campos.sql` (SQL Editor).
2. No app, clique em **⚙️** → informe **URL** e **anon key** do projeto → **Conectar**.
3. Folha e Fiscal passam a editar a **mesma base em tempo real**.

## Anexos (comprovantes)
Cada **crédito** e cada **compensação** aceita anexos (PDF/imagem — o comprovante do
PER/DCOMP). Um badge **📎** aparece na tabela; clique no anexo para abrir.
- **Modo local:** o arquivo fica no navegador (IndexedDB, até 25 MB por arquivo). É por
  navegador — anexo enviado no PC do fiscal não aparece no PC da folha.
- **Modo compartilhado:** vai para o **Supabase Storage** (bucket privado `perdcomp-anexos`,
  criado pelo `schema.sql`), aberto com link assinado de 1h. Aí todos veem o mesmo anexo.

> O comprovante do e-CAC costuma ser um PDF **digitalizado (imagem)** — serve como anexo,
> mas não dá para extrair dados dele automaticamente.

## Fluxo do dia a dia
- **Apurou crédito?** aba Créditos → *+ Novo crédito*.
- **Vai usar o crédito?** *+ Nova compensação* (departamento, débitos, nº inicial usado, nº resultante gerado). O saldo cai sozinho.
- **Quanto tem?** número grande do Painel.
- **Qual número declarar agora?** card *Próximo nº a utilizar*.

## Como o saldo é calculado (motor de cadeias — v2)
"Crédito gerado − débitos lançados" **não funciona** neste controle: o crédito rende
SELIC e alguns débitos são quitados só em parte, então a subtração global estoura
(os débitos somam mais que o crédito original). O valor confiável é o **"saldo após"
do último elo de cada corrente de DCOMP** — exatamente como o e-CAC mostra.

O app reconstrói as correntes (nº inicial → nº resultante) e soma:
1. o saldo dos elos **vivos** (nº resultante que ninguém consumiu ainda); mais
2. os **créditos não utilizados** (PER que nunca entrou em compensação).

A tabela **"De onde sai o saldo"** no painel mostra cada parcela. Cadeias paradas
há 6+ meses ganham alerta ("confirme no e-CAC").

## Números conferidos (carga v2 — planilha até 22/06/2026)
- Crédito gerado: **R$ 619.294,41** (19 competências, inclui jun/26 R$ 13.494,96)
- Débitos lançados: **R$ 714.955,46** (25 eventos — inclui SELIC/quitações parciais)
- **Saldo disponível: R$ 26.841,22**, composto por:
  - R$ 13.494,96 — crédito jun/2026 (aguardando 1º PER)
  - R$ 10.723,46 — cadeia COFINS dez/2023 (`13159.52477...3225`) — **parada há 31 meses, confirmar no e-CAC**
  - R$ 2.620,32 — cadeia IR/CSLL (`24017.71489.220626...6391`, 22/06/2026)
  - R$ 2,48 — cadeia IRPJ (`05837.87606.180526...7448`, 18/05/2026)

> A atualização SELIC segue manual: informe o *saldo após* de cada compensação
> (o valor que o e-CAC mostrar) — ele vira o valor vivo da cadeia.

## Teste
Abra `index.html?teste=1` — roda o autoteste dos cálculos (18 verificações,
incluindo o motor de cadeias: consumo de nº vivo, supersessão e evidências e-CAC).

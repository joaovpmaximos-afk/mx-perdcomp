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

## Como o saldo é calculado (motor da corrente — v3)
"Crédito gerado − débitos lançados" **não funciona** aqui: o crédito rende SELIC e
alguns débitos são quitados só em parte, então a subtração global estoura. Também
**não se somam** os saldos intermediários da corrente — cada transmissão de PER/DCOMP
consome o saldo da anterior e deixa um novo saldo, então o valor de verdade é **só o
saldo da ponta** (a última transmissão), exatamente a célula que fica destacada na
planilha e o que o e-CAC mostra em aberto.

Regra do app:
- **Disponível = "saldo após" da última transmissão da corrente** (a ponta).
- Saldos anteriores = **consumido** (já rolaram adiante).
- Saldo antigo que ficou solto (não é a ponta e ninguém consumiu o nº) → **Conferência**:
  fica sinalizado para confirmar no e-CAC, mas **não** entra no disponível.
- Crédito apurado ainda sem PER declarado → listado como **a declarar**, fora do disponível.

O painel mostra o **Extrato da corrente** (com a ponta em verde = DISPONÍVEL) e a
seção de **Conferência**.

## Números conferidos (carga v3 — planilha até 22/06/2026)
- Crédito gerado: **R$ 619.294,41** (19 competências)
- Débitos lançados: **R$ 714.955,46** (25 eventos — inclui SELIC/quitações parciais)
- **Saldo disponível hoje: R$ 2.620,32** — ponta da corrente, nº `24017.71489.220626.1.3.15-6391`
  (IR e CSLL 3ª quota, 22/06/2026). Bate com a célula amarela da planilha.
- **A conferir (não somado):** COFINS dez/2023 `13159.52477...3225` R$ 10.723,46 — parado
  há 31 meses; verificar no e-CAC se já foi usado.
- **A declarar (não somado):** crédito jun/2026 R$ 13.494,96 (ainda sem PER).

> SELIC segue manual: ao lançar uma compensação, informe o *saldo após* que o e-CAC
> mostrou — ele vira o novo saldo da ponta.

## Teste
Abra `index.html?teste=1` — autoteste dos cálculos (19 verificações, incluindo o motor
da corrente: ponta, supersessão, saldos em aberto e evidências e-CAC).

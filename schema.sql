-- ============================================================
-- MX PERDCOMP — schema Supabase (modo compartilhado)
-- Folha e Fiscal usam a MESMA base em tempo real.
-- ============================================================

create table if not exists perdcomp_creditos (
  id            text primary key,
  empresa       text not null default 'DF CAMPOS',
  competencia   text,                       -- 'AAAA-MM'
  valor_original numeric(14,2) not null default 0,
  perd_inicial  text,                        -- nº PER/DCOMP inicial
  ultima_data   date,
  saldo_manual  numeric(14,2),               -- saldo disponível atualizado c/ SELIC (opcional)
  obs           text,
  anexos        jsonb not null default '[]'::jsonb,  -- [{id,name,size,type,storage,path}] comprovantes PER
  criado_em     timestamptz default now(),
  atualizado_em timestamptz default now()
);

create table if not exists perdcomp_compensacoes (
  id                 text primary key,
  empresa            text not null default 'DF CAMPOS',
  data               date,
  competencia_debito text,
  departamento       text not null default 'FISCAL',    -- FISCAL | FOLHA
  descricao          text,
  debitos            jsonb not null default '[]'::jsonb, -- [{descricao,darf,valor}]
  valor_total        numeric(14,2) not null default 0,
  dcomp_inicial      text,                                -- nº usado
  dcomp_resultante   text,                                -- nº gerado (vira o próximo inicial)
  inis_internos      jsonb not null default '[]'::jsonb,  -- todos os nºs iniciais consumidos no evento (blocos com várias transmissões)
  saldo_apos         numeric(14,2),                       -- saldo do crédito após (c/ SELIC) = valor vivo da cadeia
  credito_id         text references perdcomp_creditos(id) on delete set null,
  usuario            text,
  obs                text,
  anexos             jsonb not null default '[]'::jsonb,  -- [{id,name,size,type,storage,path}] comprovantes DCOMP
  criado_em          date default now(),
  atualizado_em      timestamptz default now()
);

-- Config por empresa: evidências de números já consumidos no e-CAC (usadas pelo
-- motor de cadeias para não contar saldo de elo que já foi gasto em transmissão
-- registrada só no e-CAC, fora das linhas importadas).
create table if not exists perdcomp_config (
  empresa       text primary key,
  evidencias    jsonb not null default '[]'::jsonb,
  atualizado_em timestamptz default now()
);

create index if not exists idx_comp_empresa on perdcomp_compensacoes(empresa);
create index if not exists idx_comp_data    on perdcomp_compensacoes(empresa, data);
create index if not exists idx_cred_empresa on perdcomp_creditos(empresa);

-- ------------------------------------------------------------
-- RLS. Ajuste conforme o portal MAXIMOS (Supabase Auth).
-- Abaixo: qualquer usuário AUTENTICADO lê/grava (uso interno).
-- Para liberar já com a chave anon (sem login), troque
-- 'authenticated' por 'anon, authenticated'.
-- ------------------------------------------------------------
alter table perdcomp_creditos     enable row level security;
alter table perdcomp_compensacoes enable row level security;

drop policy if exists p_cred_all on perdcomp_creditos;
create policy p_cred_all on perdcomp_creditos
  for all to anon, authenticated using (true) with check (true);

drop policy if exists p_comp_all on perdcomp_compensacoes;
create policy p_comp_all on perdcomp_compensacoes
  for all to anon, authenticated using (true) with check (true);

alter table perdcomp_config enable row level security;
drop policy if exists p_cfg_all on perdcomp_config;
create policy p_cfg_all on perdcomp_config
  for all to anon, authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- Trilha de auditoria (quem mudou o quê). Opcional mas recomendado
-- para matar de vez o "desencontro" entre folha e fiscal.
-- ------------------------------------------------------------
create table if not exists perdcomp_log (
  id bigserial primary key,
  tabela text, registro_id text, acao text,
  dados jsonb, quando timestamptz default now()
);

create or replace function perdcomp_audit() returns trigger as $$
begin
  insert into perdcomp_log(tabela, registro_id, acao, dados)
  values (TG_TABLE_NAME, coalesce(NEW.id, OLD.id), TG_OP, to_jsonb(coalesce(NEW, OLD)));
  return coalesce(NEW, OLD);
end; $$ language plpgsql;

drop trigger if exists trg_audit_cred on perdcomp_creditos;
create trigger trg_audit_cred after insert or update or delete on perdcomp_creditos
  for each row execute function perdcomp_audit();

drop trigger if exists trg_audit_comp on perdcomp_compensacoes;
create trigger trg_audit_comp after insert or update or delete on perdcomp_compensacoes
  for each row execute function perdcomp_audit();

-- ------------------------------------------------------------
-- STORAGE: bucket privado para os comprovantes (PDF/imagem).
-- O app envia via chave anon e abre com URL assinada (1h).
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('perdcomp-anexos', 'perdcomp-anexos', false)
on conflict (id) do nothing;

drop policy if exists p_anexos_all on storage.objects;
create policy p_anexos_all on storage.objects
  for all to anon, authenticated
  using (bucket_id = 'perdcomp-anexos')
  with check (bucket_id = 'perdcomp-anexos');

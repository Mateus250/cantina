-- Cantina dos Jovens: cole tudo isto no SQL Editor do Supabase e clique em Run.

create table if not exists config (
  id int primary key default 1,
  products jsonb not null default '[]',
  pix text default '',
  pix_nome text default '',
  pix_cidade text default '',
  msg text default ''
);

create table if not exists pessoas (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  fone text default '',
  criado_em timestamptz not null default now()
);

create table if not exists vendas (
  id uuid primary key default gen_random_uuid(),
  numero int,                   -- número do pedido no dia (#1, #2...)
  dia date not null,
  criado_em timestamptz not null default now(),
  nome text default '',
  fone text default '',
  pessoa_id uuid references pessoas(id) on delete set null,
  itens jsonb not null,
  total int not null,           -- em centavos
  status text not null,         -- 'pago' ou 'pendente'
  metodo text,                  -- 'dinheiro', 'pix' ou vazio
  pago_em date,
  entregue boolean not null default false,
  criado_por text
);

create table if not exists dias (
  dia date primary key,
  fundo int not null default 0  -- troco inicial, em centavos
);

-- Só quem fez login mexe nos dados
alter table config  enable row level security;
alter table pessoas enable row level security;
alter table vendas  enable row level security;
alter table dias    enable row level security;

create policy "logados config"  on config  for all to authenticated using (true) with check (true);
create policy "logados pessoas" on pessoas for all to authenticated using (true) with check (true);
create policy "logados vendas"  on vendas  for all to authenticated using (true) with check (true);
create policy "logados dias"    on dias    for all to authenticated using (true) with check (true);

grant select, insert, update, delete on config, pessoas, vendas, dias to authenticated;

-- Tempo real: o que o caixa registra aparece na hora na cozinha
alter publication supabase_realtime add table config, pessoas, vendas, dias;

-- Cardápio e Pix iniciais
insert into config (id, products, pix, pix_nome, pix_cidade, msg) values (
  1,
  '[{"id":"pamonha","nome":"Pamonha","preco":1200},{"id":"bolo","nome":"Bolo de milho","preco":1000},{"id":"curau","nome":"Curau","preco":1000}]',
  'cantinaipi@gmail.com',
  'Douglas Rafagnin',
  'Campinas',
  E'Oi, {nome}! Tudo bem? Passando pra lembrar do pagamento da cantina do dia {data}: {itens}. Total: {total}.\n\nPix: {pix}\n\nOu copie o código abaixo e cole no app do banco (Pix copia e cola):\n{pixcola}\n\nObrigado!'
) on conflict (id) do nothing;

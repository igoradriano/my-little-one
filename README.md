# 🍼 Chá do Ian Levi

Aplicação web para gerenciamento de lista de presentes do chá de bebê do Ian Levi. Os convidados fazem login, escolhem itens, enviam comprovante de Pix e acompanham o status em tempo real.

---

## ✨ Funcionalidades

- **Login por convidado** — cada familiar acessa com nome e senha próprios
- **Lista de presentes** — cards com status em tempo real (disponível, escolhido, pago)
- **Divisão de item** — itens acima de R$100 podem ser divididos entre dois convidados, cada um paga metade
- **Comprovante de Pix** — convidado anexa foto/PDF do comprovante diretamente no app
- **Confirmação de pagamento** — admin aprova ou rejeita o comprovante; item pago fica permanentemente travado
- **Painel admin** — estatísticas, gestão de usuários e itens, visualização de comprovantes pendentes
- **Chave Pix e endereço** — aba dedicada com cópia rápida da chave

---

## 🛠️ Stack

| Camada | Tecnologia |
|---|---|
| Frontend | HTML + CSS + JavaScript (vanilla, sem frameworks) |
| Banco de dados | [Supabase](https://supabase.com) (PostgreSQL + Storage) |
| Hospedagem | [Netlify](https://netlify.com) |
| CI/CD | GitHub → Netlify (deploy automático no push) |
| Build | `bash build.sh` (injeta variáveis de ambiente no HTML) |

---

## 📁 Estrutura do repositório

```
cha-ian-levi/
├── index.html      # App completo com placeholders de credenciais
├── build.sh        # Script de build — substitui placeholders pelas env vars
├── netlify.toml    # Configuração do Netlify (build command + publish dir)
└── README.md
```

---

## 🚀 Deploy

### Pré-requisitos

- Conta no [GitHub](https://github.com)
- Conta no [Supabase](https://supabase.com)
- Conta no [Netlify](https://netlify.com)

---

### 1. Supabase — criar o projeto

1. Acesse [supabase.com](https://supabase.com) e crie um novo projeto
2. Escolha a região **South America (São Paulo)**
3. Aguarde a inicialização (~1 min)

---

### 2. Supabase — criar as tabelas

No **SQL Editor** (aba lateral), abra uma nova query e execute:

```sql
-- Tabela de usuários
create table users (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  pass text not null,
  is_admin boolean default false,
  created_at timestamptz default now()
);

-- Tabela de itens
create table items (
  id serial primary key,
  name text not null,
  size text default 'Único',
  price numeric not null,
  cat text default '💙',
  taken_by text references users(name) on update cascade on delete set null,
  split_with text references users(name) on update cascade on delete set null,
  split_status text check (split_status in ('pending','accepted') or split_status is null),
  pix_status text,
  pix_status_split text,
  comprovante_url text,
  comprovante_url_split text,
  created_at timestamptz default now()
);

-- RLS
alter table users enable row level security;
alter table items enable row level security;

create policy "all_users" on users for all to anon using (true) with check (true);
create policy "all_items" on items for all to anon using (true) with check (true);
```

---

### 3. Supabase — criar o bucket de comprovantes

Ainda no SQL Editor, execute:

```sql
insert into storage.buckets (id, name, public)
values ('comprovantes', 'comprovantes', true);

create policy "upload_comprovantes" on storage.objects
  for insert to anon with check (bucket_id = 'comprovantes');

create policy "read_comprovantes" on storage.objects
  for select to anon using (bucket_id = 'comprovantes');

create policy "delete_comprovantes" on storage.objects
  for delete to anon using (bucket_id = 'comprovantes');
```

---

### 4. Supabase — obter as credenciais

Vá em **Settings → API** e copie:

- **Project URL** — ex: `https://xxxxxxxxxxx.supabase.co`
- **anon public key** — chave longa na seção "Project API keys"

---

### 5. GitHub — subir o repositório

```bash
git init
git add .
git commit -m "primeiro commit"
git branch -M main
git remote add origin https://github.com/seu-usuario/cha-ian-levi.git
git push -u origin main
```

---

### 6. Netlify — conectar e configurar

1. Acesse [netlify.com](https://netlify.com) → **Add new site → Import an existing project → GitHub**
2. Selecione o repositório `cha-ian-levi`
3. O Netlify detecta automaticamente via `netlify.toml`:
   - **Build command:** `bash build.sh`
   - **Publish directory:** `dist`
4. Antes de fazer o deploy, vá em **Environment variables** e adicione:

| Key | Value |
|---|---|
| `SB_URL` | URL do seu projeto Supabase |
| `SB_KEY` | Chave anon do Supabase |
| `ADMIN_NAME` | Nome do usuário administrador |
| `ADMIN_PASS` | Senha do administrador |

5. Clique em **Deploy site**

> ⚠️ As credenciais **nunca ficam no repositório**. O `build.sh` injeta as variáveis de ambiente no HTML apenas durante o build no Netlify.

---

### 7. Atualizar o site

Qualquer alteração no código é publicada automaticamente:

```bash
git add .
git commit -m "descrição da mudança"
git push
```

O Netlify detecta o push e republica em segundos.

---

## 👥 Gerenciar usuários

### Via painel admin do app

Faça login como admin → aba **⚙️ Admin** → seção "Adicionar usuário".

### Via Supabase SQL Editor (em lote)

```sql
insert into users (name, pass, is_admin) values
('Nome do Convidado', 'senha', false),
('Outro Convidado', 'senha', false)
on conflict (name) do update set pass = excluded.pass;
```

O `on conflict` garante que usuários duplicados apenas têm a senha atualizada, sem erro.

---

## 🔄 Fluxo de pagamento

```
disponível → escolhido → pix enviado → pago ✅ (travado permanentemente)
                                     ↘ rejeitado → convidado reenvía comprovante
```

| Estado | Convidado pode cancelar? | Admin pode liberar? |
|---|---|---|
| Escolhido | ✅ Sim | ✅ Sim |
| Pix enviado | ❌ Não | ✅ Sim |
| Pago | ❌ Não | ❌ Não (só via SQL) |

### Resetar um item via SQL (para testes ou casos excepcionais)

```sql
-- Resetar item específico pelo id
update items set
  taken_by = null, split_with = null, split_status = null,
  pix_status = null, pix_status_split = null,
  comprovante_url = null, comprovante_url_split = null
where id = 1; -- troque pelo id desejado

-- Resetar todos os itens
update items set
  taken_by = null, split_with = null, split_status = null,
  pix_status = null, pix_status_split = null,
  comprovante_url = null, comprovante_url_split = null;
```

---

## 💜 Divisão de item

Itens com valor acima de **R$ 100,00** permitem divisão entre dois convidados:

1. Convidado A clica em "Escolher este 🎁" e seleciona um parceiro no dropdown
2. Um convite é enviado — convidado B vê o badge "Convite 💌" na lista
3. Convidado B aceita ou recusa
   - **Aceita** → cada um vê o item com metade do valor e pode enviar seu comprovante individualmente
   - **Recusa** → item volta para disponível
4. O item só fica 100% pago quando **ambos** tiverem o comprovante confirmado

---

## 🔑 Credenciais padrão

| Campo | Valor padrão |
|---|---|
| Admin name | Definido via `ADMIN_NAME` no Netlify |
| Admin pass | Definido via `ADMIN_PASS` no Netlify |

> Troque as credenciais padrão nas variáveis de ambiente do Netlify antes de compartilhar o link.

---

## 📦 Planos gratuitos utilizados

| Serviço | Limite gratuito | Uso estimado |
|---|---|---|
| Supabase | 500MB banco + 1GB storage | < 10MB |
| Netlify | 100GB bandwidth + 300 min build/mês | < 1GB / < 5 min |
| GitHub | Repositórios públicos ilimitados | — |

---

## 🧸 Feito com amor para o Ian Levi 💜

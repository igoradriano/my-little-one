# 🍼 Ian Levi's Baby Shower Gift Registry

A web application created to manage Ian Levi's baby shower gift registry. Family and friends can log in, choose gifts, upload Pix payment receipts, and track payment status in real time — and even chat with Ian himself.

> 💜 **A personal note**
>
> This project was built with a lot of love for my son, **Ian Levi**.
>
> More than just a web application, this repository represents a special moment in our family's life: preparing for his arrival and bringing together the people who care about him most.
>
> Every feature, screen, and line of code was created with the goal of making this celebration easier to organize while preserving the affection and excitement surrounding this very special occasion.
>
> Ian, if you ever read this in the future, know that this project was one of the many things made with love while we were waiting for you. 💜

---

## ✨ Features

* **Guest login** — each family member has their own username and password
* **Gift registry** — gift cards with real-time status (available, reserved, paid)
* **Gift splitting** — gifts above R$100 can be shared between two guests, each paying half
* **Pix receipt upload** — guests upload a photo or PDF receipt directly in the app
* **Payment confirmation** — admin approves or rejects receipts; once paid, item is permanently locked
* **5-day auto-release** — items without confirmed payment after 5 days automatically return to available
* **Admin dashboard** — statistics, user and item management, pending receipt review
* **"View in my list" shortcut** — appears on each card right after the guest selects an item
* **Chat with Ian 👶** — AI-powered chat where guests talk to Ian Levi himself, who:
  * Knows his exact gestational age (calculated in real time)
  * Describes his own fetal development using real medical knowledge
  * Knows each guest's name, nickname, and family relationship
  * Acts as an **agent** — can add/remove items, split gifts, accept/refuse invites, and navigate the app on the guest's behalf
  * Executes multiple actions at once (e.g. "add 4 items under R$300")
  * Never reveals the due date — it's a surprise! 🤫
* **Animated baby** — Ian crawls, falls, yawns, dances, bumps his head on cards, and roams the background

---

## 🛠️ Tech Stack

| Layer      | Technology                                                 |
| ---------- | ---------------------------------------------------------- |
| Frontend   | HTML + CSS + Vanilla JavaScript                            |
| Database   | Supabase (PostgreSQL + Storage)                            |
| AI Chat    | OpenRouter API (`google/gemini-2.0-flash-001`)             |
| Hosting    | Netlify                                                    |
| CI/CD      | GitHub → Netlify (automatic deploy on push)                |
| Build      | `bash build.sh` (injects environment variables into HTML)  |

---

## 📁 Repository Structure

```text
cha-ian-levi/
├── index.html      # Complete app with credential placeholders
├── build.sh        # Build script — replaces placeholders with env vars
├── netlify.toml    # Netlify config (build command + publish directory)
└── README.md
```

---

## 🚀 Deployment

### Prerequisites

* GitHub account
* Supabase account
* Netlify account
* OpenRouter account (free API key from openrouter.ai)

---

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Select the **South America (São Paulo)** region
3. Wait for initialization (~1 minute)

---

### 2. Create the Database Tables

Open the **SQL Editor** and run:

```sql
create table users (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  pass text not null,
  is_admin boolean default false,
  parentesco text,
  apelido text,
  created_at timestamptz default now()
);

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
  taken_at timestamptz,
  pix_enviado_at timestamptz,
  pix_enviado_at_split timestamptz,
  created_at timestamptz default now()
);

alter table users enable row level security;
alter table items enable row level security;

create policy "all_users" on users for all to anon using (true) with check (true);
create policy "all_items" on items for all to anon using (true) with check (true);
```

---

### 3. Create the Receipt Storage Bucket

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

### 4. Populate Guest Nicknames and Family Relationships

The Ian chat uses each guest's `apelido` and `parentesco` to personalize responses:

```sql
alter table users add column if not exists parentesco text;
alter table users add column if not exists apelido text;

update users set parentesco = 'mãe do Ian', apelido = 'Mamãe' where name = 'Layara';
update users set parentesco = 'pai do Ian',  apelido = 'Papai'  where name = 'Igor';
-- add remaining guests as needed
```

---

### 5. Get Credentials

**Supabase** — go to **Settings → API** and copy:
* Project URL (e.g. `https://xxxxxxxxxxx.supabase.co`)
* anon public key

**OpenRouter** — create a free account and generate an API key at [openrouter.ai/keys](https://openrouter.ai/keys)

---

### 6. Push to GitHub

```bash
git init
git add .
git commit -m "initial commit"
git branch -M main
git remote add origin https://github.com/your-username/cha-ian-levi.git
git push -u origin main
```

---

### 7. Connect Netlify

1. Netlify → **Add new site → Import an existing project → GitHub**
2. Select the repository — Netlify auto-detects via `netlify.toml`:
   * Build command: `bash build.sh`
   * Publish directory: `dist`
3. Add **Environment Variables** under **Site configuration → Environment variables**:

| Key              | Value                         |
| ---------------- | ----------------------------- |
| `SB_URL`         | Your Supabase project URL     |
| `SB_KEY`         | Your Supabase anon key        |
| `ADMIN_NAME`     | Administrator username        |
| `ADMIN_PASS`     | Administrator password        |
| `OPENROUTER_API_KEY` | Your OpenRouter API key   |

4. Click **Deploy site**

> ⚠️ Credentials are never stored in the repository. `build.sh` replaces placeholders only during the Netlify build.

---

### 8. Update the Website

```bash
git add .
git commit -m "describe your change"
git push
```

Netlify detects the push and redeploys automatically.

---

## 👥 Managing Users

### Through the Admin Panel

Log in as admin → **⚙️ Admin** tab → **Add User** section.

### Bulk insert via SQL

```sql
insert into users (name, pass, is_admin, parentesco, apelido) values
('Guest Name', 'password', false, 'family relationship', 'nickname'),
('Another Guest', 'password', false, 'family relationship', null)
on conflict (name)
do update set pass = excluded.pass, parentesco = excluded.parentesco, apelido = excluded.apelido;
```

---

## 🔄 Payment Flow

```text
available → reserved → receipt submitted → paid ✅ (permanently locked)
                                         ↘ rejected → guest resubmits receipt
```

| State             | Guest Can Cancel? | Admin Can Release? |
| ----------------- | ----------------- | ------------------ |
| Reserved          | ✅ Yes             | ✅ Yes              |
| Receipt Submitted | ❌ No              | ✅ Yes              |
| Paid              | ❌ No              | ❌ No (SQL only)    |

Items without confirmed payment after **5 days** are automatically released when any user logs in.

### Reset an item via SQL

```sql
-- Reset specific item
update items set
  taken_by = null, split_with = null, split_status = null,
  pix_status = null, pix_status_split = null,
  comprovante_url = null, comprovante_url_split = null, taken_at = null
where id = 1;

-- Reset all items
update items set
  taken_by = null, split_with = null, split_status = null,
  pix_status = null, pix_status_split = null,
  comprovante_url = null, comprovante_url_split = null, taken_at = null;
```

---

## 💜 Gift Splitting

Items above **R$100.00** can be shared between two guests:

1. Guest A selects a gift and picks a partner
2. Guest B receives an invite (💌 badge on the card)
3. Guest B accepts or declines
   * **Accept** → each pays half and uploads their own receipt independently
   * **Decline** → item returns to available
4. Gift is fully paid only when **both receipts** are confirmed

---

## 👶 Chat with Ian — Agent Mode

The floating 👶 button opens a chat where guests talk to Ian Levi, powered by `gpt-4o-mini`.

**What Ian knows in real time:**
- Exact gestational age (calculated from due date)
- Fetal development for that week (using the model's own medical knowledge)
- Guest's name, nickname, and family relationship
- Full current state of the gift list (available items, guest's selections, pending invites)

**What Ian can do:**
- Add or remove items from the guest's list
- Split an item with another guest
- Accept or refuse a split invite
- Navigate to a tab
- Execute multiple actions at once — e.g. *"add 4 items under R$300"* adds all 4 in a single response
- Never reveals the due date 🤫

**System prompt is rebuilt on every message** so Ian always has up-to-date context.

---

## 🔑 Default Credentials

| Field          | Default Value              |
| -------------- | -------------------------- |
| Admin name     | Defined via `ADMIN_NAME`   |
| Admin password | Defined via `ADMIN_PASS`   |

---

## 📦 Free-Tier Services

| Service  | Free Tier Limit                           | Estimated Usage     |
| -------- | ----------------------------------------- | ------------------- |
| Supabase | 500MB DB + 1GB Storage                    | < 10MB              |
| Netlify  | 100GB Bandwidth + 300 Build Minutes/Month | < 1GB / < 5 min     |
| GitHub   | Unlimited Public Repositories             | —                   |
| OpenRouter | Free tier + pay-per-use                 | ~R$0 total          |

---

## 🧸 Built with Love for Ian Levi 💜

This application was created as a small contribution to a very special moment in our lives.

While it serves a practical purpose, its real value comes from the people who helped us prepare for Ian Levi's arrival.

Thank you to everyone who participated, contributed, and shared this journey with us.

Welcome to the world, Ian Levi. 💜

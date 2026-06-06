# 🍼 Ian Levi's Baby Shower Gift Registry

A web application created to manage Ian Levi's baby shower gift registry. Family and friends can log in, choose gifts, upload Pix payment receipts, and track payment status in real time.

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
* **Gift registry** — gift cards with real-time status updates (available, reserved, paid)
* **Gift splitting** — gifts costing more than R$100 can be shared between two guests, each paying half
* **Pix receipt upload** — guests can upload a photo or PDF receipt directly through the application
* **Payment confirmation** — administrators approve or reject receipts; once paid, an item becomes permanently locked
* **Admin dashboard** — statistics, user and gift management, and pending receipt review
* **Floating cart button** — fixed shortcut in the corner of the gift list screen that shows how many items the guest has selected and links directly to their list
* **"View in my list" button** — appears on each card right after the guest selects an item, for quick navigation
* **Chat with Ian 👶** — AI-powered chat widget where guests can talk to Ian Levi himself, who responds as a baby still in the womb, knowing his gestational age, developmental stage, the guest's name, nickname, and family relationship
* **Animated baby** — Ian crawls, falls, yawns, dances, bumps his head on gift cards, climbs cards, and roams freely in the background

---

## 🛠️ Tech Stack

| Layer    | Technology                                                  |
| -------- | ----------------------------------------------------------- |
| Frontend | HTML + CSS + Vanilla JavaScript                             |
| Database | Supabase (PostgreSQL + Storage)                             |
| AI Chat  | OpenRouter API (Gemini 2.0 Flash)                           |
| Hosting  | Netlify                                                     |
| CI/CD    | GitHub → Netlify (automatic deployment on push)             |
| Build    | `bash build.sh` (injects environment variables into HTML)   |

---

## 📁 Repository Structure

```text
cha-ian-levi/
├── index.html      # Complete application with credential placeholders
├── build.sh        # Build script that replaces placeholders with env vars
├── netlify.toml    # Netlify configuration (build command + publish directory)
└── README.md
```

---

## 🚀 Deployment

### Prerequisites

* GitHub account
* Supabase account
* Netlify account
* OpenRouter account (free tier available at openrouter.ai)

---

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Select the **South America (São Paulo)** region
3. Wait for initialization (~1 minute)

---

### 2. Create the Database Tables

Open the **SQL Editor** and run:

```sql
-- Users table
create table users (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  pass text not null,
  is_admin boolean default false,
  parentesco text,
  apelido text,
  created_at timestamptz default now()
);

-- Items table
create table items (
  id serial primary key,
  name text not null,
  size text default 'One Size',
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

The chat with Ian uses each guest's nickname (`apelido`) and family relationship (`parentesco`) to personalize responses. Populate them via SQL:

```sql
alter table users add column if not exists parentesco text;
alter table users add column if not exists apelido text;

-- Example
update users set parentesco = 'mãe do Ian', apelido = 'Mamãe' where name = 'Layara';
update users set parentesco = 'pai do Ian', apelido = 'Papai' where name = 'Igor';
-- Add the remaining guests as needed
```

---

### 5. Retrieve Supabase Credentials

Navigate to **Settings → API** and copy:

* **Project URL** — e.g. `https://xxxxxxxxxxx.supabase.co`
* **anon public key**

---

### 6. Get an OpenRouter API Key

1. Create a free account at [openrouter.ai](https://openrouter.ai)
2. Go to **Keys** and generate a new API key
3. The application uses `google/gemini-2.0-flash-001` by default (free tier)

---

### 7. Push the Repository to GitHub

```bash
git init
git add .
git commit -m "initial commit"
git branch -M main
git remote add origin https://github.com/your-username/cha-ian-levi.git
git push -u origin main
```

---

### 8. Connect Netlify

1. Open Netlify → **Add new site → Import an existing project → GitHub**
2. Select the repository
3. Netlify automatically detects via `netlify.toml`:
   * Build command: `bash build.sh`
   * Publish directory: `dist`
4. Add the following **Environment Variables** under **Site configuration → Environment variables**:

| Key              | Value                            |
| ---------------- | -------------------------------- |
| `SB_URL`         | Your Supabase project URL        |
| `SB_KEY`         | Your Supabase anon key           |
| `ADMIN_NAME`     | Administrator username           |
| `ADMIN_PASS`     | Administrator password           |
| `OPENROUTER_KEY` | Your OpenRouter API key          |

5. Click **Deploy site**

> ⚠️ Credentials are never stored in the repository. `build.sh` replaces placeholders with environment variable values only during the Netlify build.

---

### 9. Update the Website

Every code change is automatically published:

```bash
git add .
git commit -m "describe your change"
git push
```

---

## 👥 Managing Users

### Through the Admin Panel

Log in as an administrator → **⚙️ Admin** tab → **Add User** section.

### Through the Supabase SQL Editor (bulk insert)

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
                                   ↘ rejected → guest uploads a new receipt
```

| State             | Guest Can Cancel? | Admin Can Release? |
| ----------------- | ----------------- | ------------------ |
| Reserved          | ✅ Yes             | ✅ Yes              |
| Receipt Submitted | ❌ No              | ✅ Yes              |
| Paid              | ❌ No              | ❌ No (SQL only)    |

### Reset an item via SQL (for testing or exceptional cases)

```sql
-- Reset a specific item by id
update items set
  taken_by = null, split_with = null, split_status = null,
  pix_status = null, pix_status_split = null,
  comprovante_url = null, comprovante_url_split = null
where id = 1;

-- Reset all items
update items set
  taken_by = null, split_with = null, split_status = null,
  pix_status = null, pix_status_split = null,
  comprovante_url = null, comprovante_url_split = null;
```

---

## 💜 Gift Splitting

Items costing more than **R$100.00** can be shared between two guests:

1. Guest A selects a gift and picks a partner from the dropdown
2. An invitation is sent — Guest B sees a "Invite 💌" badge on the card
3. Guest B accepts or declines
   * **Accept** → each guest pays half and uploads their own receipt independently
   * **Decline** → the item goes back to available
4. The gift is considered fully paid only when **both receipts** are confirmed by the admin

---

## 👶 Chat with Ian

A floating button (bottom-left corner) opens a chat widget where guests can talk to Ian Levi. Ian responds as a baby still in the womb, powered by the OpenRouter API.

**What Ian knows:**
- His exact gestational age (calculated in real time from the due date)
- His developmental stage for that week (organs forming, size, senses, movements)
- Who he is talking to — the guest's nickname and family relationship
- That a baby shower is happening right now
- **He never reveals the due date** — it's a surprise! 🤫

**System prompt is built dynamically** on every message, so Ian always knows the current week even months after deployment.

---

## 🔑 Default Credentials

| Field          | Default Value                |
| -------------- | ---------------------------- |
| Admin name     | Defined via `ADMIN_NAME`     |
| Admin password | Defined via `ADMIN_PASS`     |

> Change credentials before sharing the application link.

---

## 📦 Free-Tier Services Used

| Service      | Free Tier Limit                             | Estimated Usage  |
| ------------ | ------------------------------------------- | ---------------- |
| Supabase     | 500MB DB + 1GB Storage                      | < 10MB           |
| Netlify      | 100GB Bandwidth + 300 Build Minutes/Month   | < 1GB / < 5 min  |
| GitHub       | Unlimited Public Repositories               | —                |
| OpenRouter   | Free credits on registration + free models  | < $0.01 total    |

---

## 🧸 Built with Love for Ian Levi 💜

This application was created as a small contribution to a very special moment in our lives.

While it serves a practical purpose, its real value comes from the people who helped us prepare for Ian Levi's arrival.

Thank you to everyone who participated, contributed, and shared this journey with us.

Welcome to the world, Ian Levi. 💜

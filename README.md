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
* **Pix key and address section** — dedicated tab with one-click copy functionality

---

## 🛠️ Tech Stack

| Layer    | Technology                                                |
| -------- | --------------------------------------------------------- |
| Frontend | HTML + CSS + Vanilla JavaScript                           |
| Database | Supabase (PostgreSQL + Storage)                           |
| Hosting  | Netlify                                                   |
| CI/CD    | GitHub → Netlify (automatic deployment on push)           |
| Build    | `bash build.sh` (injects environment variables into HTML) |

---

## 📁 Repository Structure

```text
cha-ian-levi/
├── index.html      # Complete application with credential placeholders
├── build.sh        # Build script that replaces placeholders with environment variables
├── netlify.toml    # Netlify configuration (build command + publish directory)
└── README.md
```

---

## 🚀 Deployment

### Prerequisites

* GitHub account
* Supabase account
* Netlify account

---

### 1. Create a Supabase Project

1. Go to Supabase and create a new project
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

create policy "all_users" on users
for all to anon
using (true)
with check (true);

create policy "all_items" on items
for all to anon
using (true)
with check (true);
```

---

### 3. Create the Receipt Storage Bucket

Run:

```sql
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', true);

create policy "upload_receipts" on storage.objects
  for insert to anon
  with check (bucket_id = 'receipts');

create policy "read_receipts" on storage.objects
  for select to anon
  using (bucket_id = 'receipts');

create policy "delete_receipts" on storage.objects
  for delete to anon
  using (bucket_id = 'receipts');
```

---

### 4. Retrieve Supabase Credentials

Navigate to **Settings → API** and copy:

* **Project URL**
* **anon public key**

---

### 5. Push the Repository to GitHub

```bash
git init
git add .
git commit -m "initial commit"
git branch -M main
git remote add origin https://github.com/your-username/cha-ian-levi.git
git push -u origin main
```

---

### 6. Connect Netlify

1. Open Netlify → **Add new site → Import an existing project → GitHub**
2. Select the repository
3. Netlify automatically detects:

   * Build command: `bash build.sh`
   * Publish directory: `dist`
4. Add the following environment variables:

| Key          | Value                     |
| ------------ | ------------------------- |
| `SB_URL`     | Your Supabase project URL |
| `SB_KEY`     | Your Supabase anon key    |
| `ADMIN_NAME` | Administrator username    |
| `ADMIN_PASS` | Administrator password    |

5. Click **Deploy site**

> ⚠️ Credentials are never stored in the repository. The `build.sh` script injects environment variables into the HTML only during the Netlify build process.

---

### 7. Update the Website

Every code change is automatically published:

```bash
git add .
git commit -m "describe your change"
git push
```

Netlify detects the push and redeploys the application automatically.

---

## 👥 Managing Users

### Through the Admin Panel

Log in as an administrator → **⚙️ Admin** tab → **Add User** section.

### Through the Supabase SQL Editor

```sql
insert into users (name, pass, is_admin) values
('Guest Name', 'password', false),
('Another Guest', 'password', false)
on conflict (name)
do update set pass = excluded.pass;
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

---

## 💜 Gift Splitting

Items costing more than **R$100.00** can be shared between two guests:

1. Guest A selects a gift and chooses a partner
2. An invitation is sent to Guest B
3. Guest B accepts or declines

   * **Accept** → each guest pays half and uploads their own receipt
   * **Decline** → the item becomes available again
4. The gift is considered fully paid only when **both receipts** are approved

---

## 🔑 Default Credentials

| Field          | Default Value                |
| -------------- | ---------------------------- |
| Admin name     | Defined through `ADMIN_NAME` |
| Admin password | Defined through `ADMIN_PASS` |

> Change the default credentials before sharing the application link.

---

## 📦 Free-Tier Services Used

| Service  | Free Tier Limit                           | Estimated Usage |
| -------- | ----------------------------------------- | --------------- |
| Supabase | 500MB DB + 1GB Storage                    | < 10MB          |
| Netlify  | 100GB Bandwidth + 300 Build Minutes/Month | < 1GB / < 5 min |
| GitHub   | Unlimited Public Repositories             | —               |

---

## 🧸 Built with Love for Ian Levi 💜

This application was created as a small contribution to a very special moment in our lives.

While it serves a practical purpose, its real value comes from the people who helped us prepare for Ian Levi's arrival.

Thank you to everyone who participated, contributed, and shared this journey with us.

Welcome to the world, Ian Levi. 💜

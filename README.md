# 10K Everyday — setup guide

A shared step-streak board for you and your friends: the streak keeps
climbing as long as *everyone* hits 10,000 steps every day. The moment
anyone misses it, they owe the group ice cream, and the streak starts
over at zero. This app is one static page (`index.html`) plus a free
Supabase database behind it.

Two things to set up once, then it just runs:

1. **Supabase** — the shared database everyone's phone reads and writes to.
2. **GitHub Pages** — hosts `index.html` at a public URL you send to your friends.

Then, optionally, each friend sets up a **Shortcut** so their step count
posts itself from Apple Health every evening, no app-opening required.

---

## 1 · Create the Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (free tier is
   plenty for this — a handful of friends logging once a day is a tiny
   amount of data).
2. Create a new project. Pick any name/region; save the database
   password somewhere, though you won't need it for this app.
3. Once the project is ready, open **SQL Editor** (left sidebar) →
   **New query**, paste in the contents of `schema.sql` from this
   folder, and click **Run**. This creates the four tables the app
   needs (`players`, `logs`, `round_state`, `round_history`) and opens
   them up for your group to read and write.
4. Open **Project Settings → API**. You'll need two values from this
   page in the next step:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon public** key (a long string starting with `eyJ...`)

## 2 · Point the app at your project

Open `index.html` in any text editor and find this near the top of the
`<script>` block:

```js
const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
```

Replace both with the values from step 1.4, and save.

> The anon key is meant to be public — it's designed to sit in
> client-side code like this. What it *doesn't* do is add a login
> screen: anyone who has your GitHub Pages link can open the board and
> log steps under any name. For a friend group on the honor system
> that's the point (no accounts, no passwords) — just don't post the
> link anywhere public.

## 3 · Put it on GitHub Pages

**a) Create the repository on GitHub**

1. Go to [github.com/new](https://github.com/new).
2. Repository name: e.g. `10k-everyday`.
3. Keep it **Public** — GitHub Pages needs that on a free personal account
   (Private works too if you're on GitHub Pro/Team).
4. Leave "Add a README", ".gitignore" and "license" all **unchecked** — this
   folder already has its own files, and checking these causes a conflict
   when you push.
5. Click **Create repository**. On the next page, copy the URL under
   "…or push an existing repository from the command line" — it looks like
   `https://github.com/<your-username>/10k-everyday.git`.

**b) Push this folder, from Terminal on your Mac**

```bash
cd ~/Desktop/Projektid/10kEveryday
git init
git add .
git commit -m "Initial commit: 10K Everyday app"
git branch -M main
git remote add origin https://github.com/<your-username>/10k-everyday.git
git push -u origin main
```

If `git push` asks for a password, GitHub no longer accepts your account
password there — use a **Personal Access Token** instead: create one at
[github.com/settings/tokens/new](https://github.com/settings/tokens/new)
(check the **repo** scope, generate, copy it), then paste that token in
as the password when prompted (username is still your GitHub username).

**c) Turn on Pages**

1. On the repo's GitHub page, go to **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to "Deploy from a
   branch," branch `main`, folder `/ (root)`. Save.
3. GitHub gives you a URL like `https://your-username.github.io/10k-everyday/`
   within a minute or two — refresh the Pages settings page if it doesn't
   show up right away. That's the link you send your friends.
4. Open it yourself first. Since Supabase isn't wired up until step 2
   above is done, you'll see a "couldn't reach the database" message
   until you've filled in the config — once that's done, reload and you
   should see "Kes on mängus?" Add yourself, then send the link around.

**Editing later:** after any change to `index.html`, `git add index.html
&& git commit -m "update" && git push` from this same folder republishes
the site within a minute or two.

## 4 · Automatic logging from Apple Health (optional, per person)

Each friend can do this on their own phone — it's not required (typing
in a step count each day works fine too).

**Free option — a Shortcut that posts silently every evening:**

1. Open **Shortcuts** → **＋** to create a new shortcut.
2. Add **Find Health Samples** → type **Steps**, filter **Start Date
   is Today**.
3. Add **Calculate Statistics** → **Sum**, on the samples above.
4. Add **Get Contents of URL**:
   - URL: `https://YOUR-PROJECT-REF.supabase.co/rest/v1/logs`
   - Method: **POST**
   - Headers:
     - `apikey: YOUR-ANON-PUBLIC-KEY`
     - `Authorization: Bearer YOUR-ANON-PUBLIC-KEY`
     - `Content-Type: application/json`
     - `Prefer: resolution=merge-duplicates`
   - Request Body → **JSON**:
     ```json
     {
       "id": "yourname_[Current Date, ISO 8601, short]",
       "player_id": "yourname",
       "log_date": "[Current Date, ISO 8601, short]",
       "steps": [Statistic]
     }
     ```
     (`[Statistic]` and `[Current Date...]` are variables you insert
     from the picker, not typed text. `yourname` should match the
     player id shown for you in the app — open the app, tap your name
     pill top-right, and the **Set up automatic logging** panel at the
     bottom fills in this exact snippet for you already, so copying
     from there is easier than retyping it here.)
5. Go to **Automation** → **＋** → **Create Personal Automation** →
   **Time of Day** (e.g. 9:00 PM, Daily) → **Run Shortcut** → pick the
   one you made → turn off **Ask Before Running**.

From then on, your step count posts itself every evening — open the
app any time to see the board update.

**Paid option — Health Auto Export app:** if you already use it, its
**Automations → REST API** export can POST to the same URL, with the
same two headers, mapping `steps` to the day's total. More reliable
than Shortcuts if you want to fully forget about it.

---

## How the rules work

- The streak is shared: it's the number of consecutive days where
  *every* active player hit 10,000 steps.
- A day only "counts" once it's over — logging under 10k mid-day just
  shows as in-progress, not a miss.
- The first time someone doesn't reach 10k on a finalized day, that
  round ends, they're added to the ice cream ledger, and a new round
  starts the next day at zero.
- Joining mid-round only holds you to days after you joined — no
  retroactive blame.
- "Today" is based on each phone's local clock, so this assumes the
  group is roughly in one timezone.

## Files in this folder

- `index.html` — the whole app (edit the two config lines, then deploy as-is).
- `schema.sql` — run once in Supabase's SQL Editor to create the tables.
- `README.md` — this file.
- `.gitignore` — keeps macOS's `.DS_Store` files out of the repo.

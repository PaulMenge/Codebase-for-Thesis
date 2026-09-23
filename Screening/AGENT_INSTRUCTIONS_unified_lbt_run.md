# Agent task: unified LBT trajectory, anticipation & snap-back run (panel format)

## Run with
**Claude Opus 4.8 in Claude Code, VS Code.** Replaces all earlier instruction
files. Saves after EVERY municipality and runs CONTINUOUSLY until the token
budget is exhausted (no fixed batch size) — see "Run length & resumability".

## How to process — ONE municipality at a time, from a clean slate
- **Strictly sequential. Research and resolve ONE municipality completely — its own
  searches, its own fetches, its own verdict — before starting the next.** Do NOT
  batch several municipalities into shared searches or resolve a group together.
  Each row must stand on evidence gathered for THAT municipality. Batching is what
  produces cross-row triage (waving through "boring-looking" rows) and carrying a
  conclusion from one row onto another — both are errors. Take the time per row.
- **Start fresh every session. Do NOT rely on memory of any prior run.** Do not
  reuse a date, URL, snippet, or conclusion you "remember" from an earlier pass, and
  do not assume a row's answer because a previous run reached it. The only state you
  may read is the current output CSV, and only to see which `plz_kgs` are already
  written (so you skip them) — never to copy their reasoning. Every verdict must come
  from evidence you retrieved THIS session for THIS row. If a fact isn't in a document
  you have opened in this session, it is not established.

## THE ONE QUESTION (everything below serves this)
For each municipality you are answering a single question:

> **Was the 2024 Hebesatz change knowable before 1 November 2023?**

"Knowable" means a public, dated commitment to the 2024 rate existed before that
date — by ANY route, and the route does not matter: a multi-year plan resolved in
2021, a Doppelhaushalt passed in spring 2023, a press announcement in October
2023, a council resolution on 30 October 2023 — all are `anticipated`, equally.
A change first committed on or after 1 November 2023 is `retained`, even if it was
implemented 1 January 2024. The cutoff is about WHEN IT BECAME KNOWN, not how, not
how far in advance, and never the implementation date.

Everything else in this file — trajectory, regime, snap-back decomposition — is a
TOOL to answer that one question accurately (mainly: to find the right document to
date, and to protect the treatment variable). None of it is the goal, and none of
it changes the `decision`:
- Regime classification only tells you WHICH document commits the 2024 rate (a
  multi-year path points to an earlier originating Satzung; a single change points
  to the 2024 budget). It is a search-targeting aid, nothing more.
- The snap-back decomposition answers a SEPARATE treatment-construction question
  and **never by itself sets `decision`**. But a reversion CAN be `anticipated` —
  under one specific, documented condition:
  - **If the original cut was explicitly temporary with a stated end date** (e.g.
    the 2020/2021 Satzung says the reduction is *befristet bis 31.12.2023* or
    otherwise fixes when the rate returns), then the 2024 reversion WAS committed
    in advance. If that sunset was set before 2023-11-01 → `anticipated`. The
    decisive document here is the **original cut's resolution**, not a 2024 budget.
  - **If the original cut was open-ended** (just lowered the rate, no stated expiry),
    then the mere fact that it later reverted is NOT anticipation — nobody knew in
    Nov 2023 if/when it would snap back → `retained` (unless a separate pre-cutoff
    document committed the 2024 rate).
  So: do not collapse "it was mechanically a reversion" into "anticipated"; but DO
  flag it anticipated when the reversion's timing was itself fixed in advance by a
  pre-cutoff document. Same proof gate applies.

## Guiding principle
**The lag columns give the full rate history, so trajectory, regime, and snap-back
are computed MECHANICALLY with zero search. Search is spent ONLY to date and
document the one resolution that committed the 2024 rate.** Knowing the exact
rate values a valid document must contain makes matching strict and cheap.

---

## Input format — read EXACTLY this schema

`/mnt/user-data/uploads/2024_lbt_change_check.md` — it is a **CSV** (comma-sep,
quoted fields with commas in names, UTF-8). Columns:
`bundesland, kreis, gemeinde, plz_kgs, year, lbt, lbt_change,
lbt_lag_1, lbt_lag_2, lbt_lag_3, lbt_lag_4, lbt_lag_5, lbt_lag_6, lbt_lag_7, lbt_lag_8`

Semantics (do NOT re-derive these):
- `year` = 2024 for all rows. `lbt` = the 2024 Hebesatz level.
- `lbt_lag_k` = the level k years before 2024. So **lag_1 = 2023, lag_2 = 2022,
  lag_3 = 2021, lag_4 = 2020, lag_5 = 2019, lag_6 = 2018, lag_7 = 2017,
  lag_8 = 2016.**
- `lbt_change = lbt − lbt_lag_1` (the studied 2023→2024 change). It is already in
  the file — use it; do not recompute except as a consistency check.
- **Pre-COVID baseline = lag_5 (2019)**, with lag_6 (2018) as fallback/confirmation.
- **COVID/dip window = lag_4..lag_1 (2020–2023).**

### Handling the data carefully
- `bundesland`, `kreis`, `gemeinde` are clean text columns — use them directly for
  the match gate. No AGS decoding needed. `plz_kgs` is the numeric AGS (zero-pad
  to 8 only if you need the canonical AGS string; geography already provided).
- **Empty lag cells = MISSING, never zero.** A blank means "no data for that year",
  NOT a rate of 0 and NOT "no change". Skip missing years when building the
  trajectory; never treat blank as a level or impute one.
- **Decimals exist** (e.g. 382.5, 333.75). Keep them. Values like
  `347.3333435058594` are float-precision artifacts — round to 2 dp for display
  and comparison, but flag in notes if a fractional Hebesatz looks implausible.
- Names may contain commas inside quotes (e.g. `"Peine, Stadt"`) — parse as CSV,
  not by splitting on commas.

---

## Per municipality — in order

### STEP 1 — Trajectory (mechanical, no search)
Assemble the level sequence 2016→2024 from lag_8…lag_1 then lbt, skipping missing
years. Record `trajectory` (e.g. `255('16)→267('18)→285('21)→380('24)`) and the
list of years where the level changed (`change_years`).

### STEP 2 — Regime classification (mechanical, no search)
Label from the trajectory:
- `single_2024` — flat across available lags, one change only at 2023→2024.
- `multiyear_path` — 2023→2024 is one step of a monotonic multi-step climb/descent
  (e.g. Peine 425→430→435→440; Villingen-Schwenningen 360→370→380→390). Record the
  step sequence.
- `covid_dip_recover` — level dipped below the 2019 baseline (lag_5) anywhere in
  2020–2023 (lag_4..lag_1) and rose back toward/above it by 2024 (e.g. Langenfeld
  360→…→299→360). Window per lag_5, NOT just lag_3/lag_4.
- `flat_then_jump` — long flat then a single large 2024 move, no prior dip.
- `volatile` — multiple mixed-sign changes, no clean pattern (e.g. Wassenberg
  411→395→…→395→420).
Record `regime` and one-line `regime_basis`.

### STEP 3 — Snap-back decomposition (mechanical, no search; only if a dip exists)
If `covid_dip_recover` (or any sub-baseline year precedes 2024):
- `depression_window` — span of years below the 2019 baseline.
- `baseline_2019` = lag_5 (note if lag_5 missing → use lag_6, record which).
- `reversion_component = min(lbt, baseline) − lbt_lag_1`
- `netnew_component = lbt − max(lbt_lag_1, baseline)` if `lbt > baseline`, else 0.
- These sum to `lbt − lbt_lag_1`. Also record `rev_vs_2018` using lag_6 as an
  alternative baseline, since the right baseline is the user's modelling choice
  (Langenfeld is +30/+30 vs 2019 but a clean +61 pure reversion vs 2018 — record
  both, choose neither).
- `change_matches_file` = yes/no: does `lbt − lbt_lag_1 == lbt_change`? If no, a
  data-quality issue — describe precisely in notes.

### STEP 4 — Which document to date
Anticipation question: **was the 2024 rate committed before 2023-11-01?**
- `multiyear_path` → the **originating Satzung that first fixed the 2024 rate**
  (often a 2021/2022 resolution). Its date governs.
- `covid_dip_recover` → check the **original cut's resolution** for a stated sunset
  / *Befristung* (an end date returning the rate in 2024). If such a dated sunset
  exists and is pre-cutoff, THAT is the governing document → the reversion was
  anticipated. If the cut was open-ended (no stated expiry), the reversion is NOT
  anticipated by itself — fall back to checking for a separate 2024 resolution.
- otherwise → the **2024 Haushaltssatzung / Hebesatzsatzung** resolution.
Search only for THIS document (per branch above).

### STEP 5 — Search, date, apply cutoff (the only search step)

**MANDATORY per-municipality search — no triage skipping.** EVERY municipality
gets its own governing-document search before it can be marked `retained`. You may
NOT pre-judge a row as "obviously routine / post-cutoff" and retain it without
searching. Processing in geographic blocks is fine for ordering, but a block must
NOT be used to wave through rows you assume are boring: a routine-looking 2024
budget can still hide a pre-cutoff Doppelhaushalt or an early announcement, and
that is exactly the false negative this run exists to prevent. A `retained` is only
valid as one of: `hit_post_cutoff` (found a dated document on/after the cutoff),
`hit_no_date` (found the document but no usable date), or `no_hit` (searched and
found nothing) — each meaning a search was actually run. A `retained` row with no
search performed is not acceptable. (Mechanical Steps 1–3 still need no search; this
clamp is about the anticipation verdict only.)

Date-anchored German queries (`"<gemeinde>" Hebesatz 2024 Satzung Bekanntmachung`,
`"<gemeinde>" Gewerbesteuer Hebesatz Beschluss 2023`, for multiyear add
`2024 2025`). Prefer municipality domain / Amtsblatt / RIS. Stop once the governing
document + date are found, or after ~2–4 searches + 1–2 fetches.
- Decisive date strictly before **2023-11-01** → `decision = anticipated`.
  On/after, undated, or not found → `decision = retained` (default).
- Implementation date (2024-01-01) is irrelevant.

### Hard gates for `anticipated` (all required)
1. **Match** — document is THIS `gemeinde` in THIS `kreis`/`bundesland`. Wrong
   kreis = REJECT → retained.
2. **Level consistency** — document's stated old/new rates must agree with the
   panel (lbt and lbt_lag_1, or the multiyear step). Contradiction = not valid
   proof → retained, note it.
3. **Reconcile** — extracted `doc_hebesatz_old`/`doc_hebesatz_new`; `new−old` must
   match the relevant transition, else `mismatch` → retained.
4. **Date** — unambiguous, strictly before 2023-11-01.
5. **Hand-verifiable proof** — `doc_url` direct/stable/public (no search/RIS-nav
   URL; if RIS-only, give click-path in notes); `doc_locator` (page/§/TOP);
   `proof_snippet` verbatim German quote with BOTH rate value AND date;
   `resolution_date` = the date in that snippet.
6. **Document actually retrieved — pattern is never proof, a fetch failure is never
   evidence.** A regularity in the lag panel (e.g. a clean +5pp/year lockstep that
   "looks like" an HSK path) MAY trigger a search, but NEVER on its own satisfies the
   `anticipated` gate — a lockstep can also arise from independent annual decisions,
   each resolved in its own December and individually unanticipable. You may only flag
   `anticipated` when you have SUCCESSFULLY OPENED the governing document and read the
   pre-cutoff date in it. A 403, paywall, timeout, or any other failed fetch is NOT a
   search result and NOT a basis to flag: it means "I could not open this door", not
   "the commitment exists". On a failed fetch, look harder before giving up — retry
   with a browser user-agent via curl (this has worked on municipal 403s), try an
   alternate host (Kreis/Kommunalaufsicht Genehmigung, council RIS minutes, a cached
   budget), or reformulate the search. If after genuine effort the document still
   cannot be opened and read, the row is `retained` with status `hit_no_date` and a
   note (e.g. "panel suggests HSK path but originating resolution not retrievable this
   session"). Never write an `anticipated` row whose `doc_url` you could not open —
   that produces an undefendable drop (a reader clicking the link gets denied).
Any gate unmet → `retained`. Default is retained; a missed announcement is
acceptable, a false drop is the costly error.

---

## Output — `/mnt/user-data/outputs/lbt_unified_audit.csv`, one row per plz_kgs
Columns:
`plz_kgs, gemeinde, bundesland, kreis, lbt, lbt_lag_1, lbt_change,
trajectory, change_years, regime, regime_basis,
depression_window, baseline_2019, reversion_component, netnew_component,
rev_vs_2018, change_matches_file,
governing_doc_type, status, decision, doc_hebesatz_old, doc_hebesatz_new,
delta_reconciles, resolution_date, date_basis, doc_url, doc_locator,
proof_snippet, notes`

`status ∈ {hit_pre_cutoff, hit_post_cutoff, hit_no_date, mismatch, no_hit,
ambiguous}`; `decision ∈ {anticipated, retained}`.

## Run length & resumability (IMPORTANT — changed behaviour)
- On start, read the existing output CSV if present, build the set of completed
  `plz_kgs`, print done/remaining counts, and process ONLY the remaining rows in
  file order.
- **Append and flush ONE row to disk immediately after each municipality is
  resolved, before starting the next.** Never buffer multiple rows in memory.
  **Do NOT accumulate a block of rows in a side-file and concatenate at the end of
  the block** — that risks losing the whole in-progress block on a crash instead of
  just one municipality. Write row-by-row directly to the output CSV. If you compute
  rows in a block for convenience, still append each row to the live CSV as it is
  finished, not as a batch.
- **Do NOT stop at a fixed batch size. Keep processing municipalities
  continuously until the token/context budget is exhausted or all 242 are done.**
  When the session ends (tokens used up or interrupted), the CSV already holds
  every completed row; the next session resumes automatically from the first
  unfinished `plz_kgs`. The single in-flight municipality at cutoff simply re-runs
  next session (its row was never written), so no finished work is lost.
- Periodically (say every ~10 rows) print a brief progress line so the user can
  see liveness, but do not pause or wait for input.

## Overnight unattended running (resume-on-relaunch contract)
The goal is to let the run continue across the night, consuming token budget as it
replenishes after a limit is hit. IMPORTANT: once a session ends because the
token/usage limit is reached, this agent cannot restart itself — the model is no
longer executing, so it cannot "wait an hour and retry" from inside. Automatic
overnight continuation therefore requires an EXTERNAL scheduler (OS-level) that
relaunches Claude Code on a timer; this agent's only job is to resume cleanly each
time it is relaunched. To make that reliable:
- On EVERY launch, immediately read the existing output CSV, build the set of done
  `plz_kgs`, print "resuming: N done, M remaining", and continue from the first
  unfinished row. Never restart from row 1 if the CSV has rows.
- If launched while still rate-limited (no tokens available), exit cleanly without
  writing partial/garbage rows, so the next scheduled relaunch can try again.
- Because each row is flushed immediately and verdicts use only this-session
  evidence, any number of stop/relaunch cycles is safe and lossless — a relaunch
  simply continues the queue.
The external relaunch mechanism (e.g. Windows Task Scheduler firing hourly, or a
shell loop `while true; do <launch>; sleep 3600; done`) is set up by the user
outside this file; the contract above guarantees the agent does the right thing
whenever that mechanism wakes it.

## End-of-run summary (whenever the run stops)
Print: how many of 242 are now complete and how many remain; regime counts so
far; every `anticipated` row with its `doc_url` + `doc_locator`; every
`change_matches_file = no` row (data-cleaning queue); every `covid_dip_recover`
row with both decompositions. Remind the user: hand-verify each anticipated flag
against its source before dropping; the run itself drops/flags nothing —
`decision` proposes, the user disposes.

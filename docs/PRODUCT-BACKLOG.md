# FamilyTasks — Product Backlog (UX/BA plan)

**Status:** Planning only — **no implementation yet**  
**Source:** UX/UI + BA review (sections 2.1, 2.2, Undo from 2.3, 2.4, 3 without Today/Later, 4, 5, 6)  
**Date:** 2026-07-18  
**Env assumptions:** Android emulator, 2 Google accounts, Firestore rules deployed, iOS out of scope  

---

## Goals

| Goal | How we measure |
|------|----------------|
| User understands filters / empty list | Fewer “app is empty” moments; reset filters used |
| Second user joins and acts | Invite → join → first task / assignment |
| Analytics drive action | Taps from Dashboard open correct Tasks filters |
| Safer Done | Undo after mark done is used / fewer accidental dones |
| Faster scan of long lists | Overdue first, search, avatars, long-press |
| Clearer family model | Personal vs Family, permissions, invite lifecycle |
| Polish without redesign | Spacing, skeletons, haptics |

---

## Scope map (included)

| Ref | Topic | In backlog |
|-----|--------|------------|
| **2.1** | Empty + reset filters; visible status filter; overdue cue | Yes |
| **2.2** | Family onboarding (create / join / first assign) | Yes |
| **2.3** | **Only Undo Done** (not full snackbar suite) | Yes |
| **2.4** | Dashboard → Tasks deep navigation | Yes |
| **3** | Sort, long-press menu, assignee avatar, search | Yes |
| **3 excl.** | Sections Today / Later | **Out** |
| **4** | Permissions copy, create help, invite expiry, recurring | Yes |
| **5** | Dashboard next: overload, week compare, share | Yes (after 2.4) |
| **6** | Spacing, skeletons, haptics, contrast check | Yes |

---

## Principles for implementation (later)

1. Prefer existing providers (`taskViewFilterProvider`, `taskStatusFilterProvider`, `tasksProvider`).  
2. No new backend unless required (invite expiry may need Firestore fields).  
3. UI language stays **English**.  
4. Keep speed-list UX (dense rows, filter pills B, status popup).  
5. Each iteration should be **demoable** and **manually testable**.

---

# Iteration plan overview

| Iter | Theme | Focus | Rough effort* | Depends on |
|------|--------|--------|---------------|------------|
| **7** | Clarity & safety | 2.1 + Undo | S–M | — |
| **8** | Actionable analytics | 2.4 + Dashboard P0/P1 core | M | 7 optional |
| **9** | List power tools | Sort, search, long-press, avatars | M | 7 nice |
| **10** | Family growth | Onboarding 2.2 + permissions/help 4 | M | — |
| **11** | Invites & rhythm | Invite lifecycle + recurring | M–L | 10 |
| **12** | Dashboard depth + polish | 5 remainder + 6 | S–M | 8 |
| **13** | Email auth | Register / sign-in / reset + name | M | — |
| **14** | Email verification | Optional verify banner + resend; edit name | S–M | 13 |
| **15** | Account linking | Link Google ↔ email on same uid | M | 13 |

\*S ≈ 0.5–1 day, M ≈ 1–3 days, L ≈ 3–5+ days (one developer, app-level estimate)

```text
7 Clarity ──► 8 Dashboard nav ──► 12 Dashboard+ / polish
       └──► 9 List tools
10 Family UX ──► 11 Invite + recurring
```

Order can be adjusted: **7 first** is strongly recommended (cheap, high trust).

---

# Iteration 7 — Clarity & safety  
**Theme:** «Понятно, что отфильтровано; ошибку Done можно откатить»  
**Includes:** 2.1 (all), 2.3 Undo  

## Epic E7.1 — Empty states & filter recovery

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-7.1.1** | As a user with filters that hide all tasks, I want to see why the list is empty and reset filters in one tap | Given tasks exist but filtered list is empty: empty title/subtitle mention filters; primary CTA **Reset filters** restores defaults (view + status per product rules); secondary **New task** remains | P0 |
| **US-7.1.2** | As a user, I want empty state when there are truly zero tasks to stay clear | When global task list empty: no “reset filters” (or disabled/hidden); keep create CTA | P1 |

**Notes:** Need helper: `hasAnyTasks` vs `filteredEmpty`. Reset = e.g. For me + To Do if remember ON, else All + All statuses — align with existing prefs.

## Epic E7.2 — Visible status filter

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-7.2.1** | As a user, I want to see which status filter is active without opening the menu | AppBar shows status label chip or subtitle (e.g. **To Do ▾** / **All statuses ▾**); tappable opens same status popup; badge on icon can stay or merge into chip | P0 |

## Epic E7.3 — Overdue visibility

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-7.3.1** | As a user, I want overdue tasks to stand out in the list | Overdue open tasks show a small **Overdue** badge or icon label on the row (in addition to red date); Done tasks never show overdue | P0 |

*(Full sort order is Iteration 9 — here only visual cue.)*

## Epic E7.4 — Undo Done

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-7.4.1** | As a user who marked a task Done by mistake, I want Undo | After Done via checkbox, swipe, or detail quick status: SnackBar **Task marked as done** + **Undo** (~5s); Undo sets status back to previous (at least To Do); works for allowed users only | P0 |
| **US-7.4.2** | Undo does not break notifications/reminders inconsistently | If Done cleared reminder, Undo restores reminder only if still in future **or** document behavior “reminder not restored” in release notes — pick one and test | P1 |

## Iteration 7 — Out of scope

- Dashboard navigation  
- Search / sort pipeline  
- Onboarding  
- Invite expiry  

## Iteration 7 — Definition of Done

- [x] Manual smoke: empty filtered list → Reset *(implemented; await user QA)*  
- [x] Status visible in AppBar  
- [x] Overdue badge on ≥1 task  
- [x] Undo after checkbox + swipe Done (+ detail)  
- [x] `flutter analyze` clean *(verify on implement)*  
- [x] QA cases added/updated in `QA/` (when implementing)

## Iteration 7 — Demo script

1. Create 2 tasks; filter so list empty → Reset.  
2. Set status To Do; show AppBar label.  
3. Past/near deadline overdue appearance.  
4. Mark Done → Undo → task open again.

---

# Iteration 8 — Actionable analytics  
**Theme:** «Цифра на Dashboard = действие в Tasks»  
**Includes:** 2.4, 5 (P0 + part of P1)  

## Epic E8.1 — Dashboard → Tasks deep links

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-8.1.1** | As a user on **My** dashboard, I can open Tasks with matching personal context | Tap Overview **Overdue** → Tasks, status suitable to show open tasks (All or keep status but view shows overdue — define: prefer **status = All** + sort/highlight overdue later); tap workload **For me** / **By me** sets `TaskViewFilter` accordingly | P0 |
| **US-8.1.2** | As a user on **Family** dashboard, I can open Family tasks | Tap overview / family completion area → Tasks + view filter **Family** | P0 |
| **US-8.1.3** | As a user, tapping a status breakdown row filters Tasks by that status | By status rows (To Do / In Progress / Done) set `taskStatusFilterProvider` and navigate to Tasks | P0 |
| **US-8.1.4** | Overdue list rows still open task detail (existing); optional “See all overdue” | Keep detail navigation; if only 5 shown, optional footer **See all** → Tasks + overdue-focused filters | P1 |

**Technical note (for later):** Introduce a small navigation intent / provider, e.g. `tasksOpenIntentProvider`, consumed once by `TasksScreen` on tab focus — avoid race with filter persistence.

## Epic E8.2 — Family “who is overloaded” (Dashboard 5 P1)

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-8.2.1** | As a family member, I see who has many open assigned tasks | On Family tab member list: highlight members with open assigned count ≥ threshold (e.g. 3); visual only or tappable later | P1 |

## Epic E8.3 — Week comparison (Dashboard 5 P1)

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-8.3.1** | As a user, I see this week vs last week completion | One line under completion or 7-day chart: e.g. **Done this week: 5 (↑2 vs last week)**; computed from task `updatedAt` when Done | P1 |

## Iteration 8 — Out of scope

- Share summary (→ Iter 12)  
- Recurring tasks  
- Full empty-state work (Iter 7)  

## Iteration 8 — Definition of Done

- [x] My + Family dashboard taps land on correct Tasks filters  
- [x] Status row taps work  
- [x] Overload highlight (Busy if open ≥ 3)  
- [x] Week delta line (Done this week vs last)  
- [x] See all overdue  
- [ ] Manual multi-tab smoke *(user QA)*  

## Iteration 8 — Demo script

1. My → Overdue tile → Tasks shows overdue-related list.  
2. Family → completion → Family filter.  
3. By status → Done → only done tasks.

---

# Iteration 9 — List power tools  
**Theme:** «Длинный список остаётся быстрым»  
**Includes:** section 3 without Today/Later  

## Epic E9.1 — Default sort

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-9.1.1** | As a user, important tasks appear first | Default sort: **Overdue (open)** → **deadline ascending (nulls last)** → **priority high first** → `updatedAt` desc; applies to all view/status filters | P0 |

## Epic E9.2 — Search

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-9.2.1** | As a user, I can search tasks by title (and description) | Search icon or field on Tasks; filters current list client-side; empty search state message; clears easily | P0 |

## Epic E9.3 — Long-press quick actions

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-9.3.1** | As a user, I can act without swipe | Long-press row → bottom sheet/menu: **Mark done** / **Edit** (if allowed) / **Delete** (if allowed); respects permissions; Done uses Undo from Iter 7 | P0 |

## Epic E9.4 — Assignee avatar

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-9.4.1** | As a user, I scan assignees faster | Personal tasks show circular initial (or photo if available) instead of/in addition to long “For: Name”; Family tasks keep Family label | P1 |

## Iteration 9 — Out of scope

- Today / Later sections  
- Server-side search  

## Iteration 9 — Definition of Done

- [x] Sort order verified with mixed deadlines/priorities *(implemented)*  
- [x] Search finds by title  
- [x] Long-press actions + permission checks  
- [x] Avatar on personal rows  
- [ ] Manual smoke *(user QA)*  

## Iteration 9 — Demo script

1. Mix overdue + future + no deadline → order correct.  
2. Search half-title.  
3. Long-press Done + Delete cancel.  
4. Show assignee avatars.

---

# Iteration 10 — Family growth & clarity  
**Theme:** «Второй пользователь понимает продукт»  
**Includes:** 2.2, part of 4 (copy/permissions, not expiry/recurring)  

## Epic E10.1 — Onboarding after create group

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-10.1.1** | As a new owner, I know to invite someone | After successful create group: dialog or banner **Invite someone to assign tasks** + CTA → Invite screen; dismissible once (persisted) | P0 |

## Epic E10.2 — Onboarding after join

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-10.2.1** | As a new member, I know next step | After join success: short message **You’re in · Check For me or create a Family task** + optional CTA Tasks / Create | P0 |

## Epic E10.3 — First assignment tip

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-10.3.1** | As creator assigning to another member first time | After first successful create with assignee ≠ self: one-time tip **They’ll see it under For me** | P1 |

## Epic E10.4 — Permissions & type clarity (4)

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-10.4.1** | As assignee without edit rights, I understand why | Detail (and edit denied path): copy **Only the creator can edit this task** when applicable | P0 |
| **US-10.4.2** | As creator, I understand Personal vs Family | Task form under type toggle: one-line help **Family tasks are visible to everyone in your family** | P0 |

## Iteration 10 — Out of scope

- Invite expiry (Iter 11)  
- Recurring (Iter 11)  

## Iteration 10 — Definition of Done

- [x] Create group → invite prompt once  
- [x] Join → next-step message  
- [x] Permission + Family help copy live  
- [x] One-time flags in Hive/prefs  
- [ ] Manual smoke *(user QA)*  

## Iteration 10 — Demo script

1. Fresh owner creates group → invite CTA.  
2. B joins → guidance.  
3. A assigns to B → tip.  
4. B opens task → cannot edit + explanation.

---

# Iteration 11 — Invites & recurring rhythm  
**Theme:** «Семья живёт по правилам и привычкам»  
**Includes:** rest of 4  

## Epic E11.1 — Invite lifecycle

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-11.1.1** | As owner, invite codes expire | Code has expiry (e.g. 48h or 7d); expired join shows clear error | P0 |
| **US-11.1.2** | As owner, I can regenerate invite | Invite screen: **Regenerate** invalidates old code; new code works | P0 |
| **US-11.1.3** | Show expiry to owner | UI shows expires at / countdown | P1 |

**Data:** extend invite document (`expiresAt`, `revoked` / new code id). Rules may need update.

## Epic E11.2 — Recurring tasks

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-11.2.1** | As a user, I can create a weekly recurring task | Form option: None / Weekly (weekday); on Done, next occurrence created (or schedule generated) with clear rules documented | P0 |
| **US-11.2.2** | Recurrence visible in UI | Detail/list hint **Repeats weekly**; edit can turn off | P1 |

**Complexity:** highest of backlog — may split into 11a (data model) + 11b (UI) if needed.

## Iteration 11 — Definition of Done

- [x] Expired invite rejected  
- [x] Regenerate works (revokes previous pending)  
- [x] Weekly recurrence happy path A→done→next (+7 days)  
- [x] Expires label on invite UI  
- [x] Help EN/RU updated  
- [ ] Manual smoke *(user QA)*  
- [x] Rules: no change required (invites already create/update by signed-in)  

## Iteration 11 — Demo script

1. Old code fails; new code joins.  
2. Weekly chore → Done → next week instance appears.

---

# Iteration 12 — Dashboard depth + visual polish + recurrence expand  
**Theme:** «Приятно и делиться; UI ровный; Daily/Monthly»  
**Includes:** 5 remainder, 6, expanded Repeat  

## Epic E12.0 — Repeat: Daily & Monthly

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-12.0.1** | As a user, I can set Daily or Monthly repeat on a task | Form Repeat: **No repeat / Daily / Weekly / Monthly**; on Done spawn next with +1 day / +7 days / +1 calendar month; same title/assignee/priority/type; new status To Do | P0 |
| **US-12.0.2** | Repeat is visible in detail | Detail shows Daily/Weekly/Monthly label; edit can change/clear | P1 |

## Epic E12.1 — Share family summary (5 P2)

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-12.1.1** | As a member, I can share a short progress summary | Button on Family dashboard: share text e.g. **Family closed 12/15 tasks · 2 overdue** via system share sheet | P2 |

## Epic E12.2 — UI system polish (6)

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-12.2.1** | Consistent section spacing | Tasks / Dashboard / Settings vertical rhythm documented (e.g. 16/20) and applied | P1 |
| **US-12.2.2** | Skeleton loading | Tasks list + Dashboard show skeleton placeholders instead of only spinner | P1 |
| **US-12.2.3** | Haptics | Light haptic on Done and Delete confirm (Android) | P2 |
| **US-12.2.4** | Contrast check | Overdue red vs selected teal reviewed on emulator; adjust tokens if needed | P2 |

## Iteration 12 — Definition of Done

- [x] Daily / Monthly repeat spawn on Done  
- [x] Share works (system sheet)  
- [x] Skeletons on load  
- [x] Spacing tokens (`AppSpacing`)  
- [x] Haptics + contrast (`danger` token)  
- [ ] Manual smoke *(user QA)*  

---

# Iteration 13 — Email register / sign-in / reset  
**Theme:** «Можно без Google»  
**Includes:** Firebase Email/Password, display name on register  

## Epic E13.1 — Email account

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-13.1.1** | As a user without Google, I can create an account | Login: name + email + password + confirm; min 8 chars; Firebase createUser + `updateDisplayName`; lands on Tasks | P0 |
| **US-13.1.2** | As a user, I can sign in with email | Login: email + password; friendly errors (wrong password, unknown email) | P0 |
| **US-13.1.3** | As a user, I can reset a forgotten password | Forgot password → reset email via Firebase; snackbar success | P0 |
| **US-13.1.4** | My name is visible to family | `displayName` stored on Auth + `users/{uid}`; used in Settings and members | P0 |

**Out of scope (later iters):** mandatory email verification, account linking, edit name in Settings.

## Iteration 13 — Definition of Done

- [x] Google still available on Login (variant K)  
- [x] Email sign-in / register / reset  
- [x] Display name on register  
- [x] Firestore profile filled if name arrives after first snapshot  
- [ ] **Console:** enable Email/Password in Firebase Authentication  
- [ ] Manual smoke *(user QA)*  

---

# Iteration 14 — Email verification (hard gate)  
**Theme:** «Семья только после подтверждения почты»  
**Depends on:** 13  

| ID | User story | Pri |
|----|------------|-----|
| **US-14.1** | After register, send verification email | P0 |
| **US-14.2** | Tasks / personal work immediately; Family create/join locked until verified | P0 |
| **US-14.3** | Settings + Family: Resend + “I have verified” (reload) | P0 |
| **US-14.4** | Firestore: group/member/invite create requires `email_verified` | P0 |

Edit display name → still **Iteration 15 leftover** or later; not in this hard-gate slice.

## Iteration 14 — Definition of Done

- [x] Verification mail on register  
- [x] Family UI gated; repo + rules reject unverified create/join  
- [x] Resend / refresh  
- [ ] Deploy `firestore.rules`  
- [ ] Manual smoke *(user QA)*  

---

# Iteration 15 — Account linking  
**Theme:** «Один человек — Google и email»  
**Depends on:** 13  

| ID | User story | Pri |
|----|------------|-----|
| **US-15.1** | Signed in with email, I can link a Google account | P1 |
| **US-15.2** | Signed in with Google, I can add email + password | P1 |
| **US-15.3** | Same `uid`; handle `credential-already-in-use` | P0 |

## Iteration 15 — Definition of Done

- [x] Settings → Sign-in methods: Link Google / Add email+password  
- [x] Same Firebase uid after link  
- [x] Friendly errors: already in use, already linked, recent login  
- [ ] Manual smoke *(user QA)*  

---

# Iteration 16 — Edit display name  
**Theme:** «Поменять имя в профиле»  
**Size:** S  

| ID | User story | Pri |
|----|------------|-----|
| **US-16.1** | As a user, I can edit my display name in Settings | P1 |
| **US-16.2** | Name updates Auth, `users/{uid}`, and group member doc if any | P1 |

## Iteration 16 — Definition of Done

- [x] Settings profile → Edit name dialog  
- [x] Auth + Firestore user + member doc  
- [ ] Manual smoke *(user QA)*  

---

# Cross-cutting backlog (any iteration)

| ID | Item | Notes |
|----|------|--------|
| **XC-1** | Settings copy for local new-task notifications honesty | Short subtitle; can ship in 7 or 10 |
| **XC-2** | QA suite updates per iteration | Extend `QA/TESTCASES.md` |
| **XC-3** | Filter persistence vs deep links | Deep link must win once, then persist if Remember ON |
| **XC-4** | No Today/Later sections | Explicit non-goal until reopened |

---

# Priority stack (if only one iter at a time)

1. **Iter 7** — Clarity & Undo  
2. **Iter 8** — Dashboard → Tasks  
3. **Iter 9** — Sort / Search / Long-press  
4. **Iter 10** — Onboarding + copy  
5. **Iter 11** — Invites + Recurring  
6. **Iter 12** — Share + polish  
7. **Iter 13** — Email auth  
8. **Iter 14** — Email verification + edit name  
9. **Iter 15** — Account linking  
10. **Iter 16** — Edit display name  

---

# Story points cheat sheet (optional)

| Size | Meaning |
|------|---------|
| S | 1 screen copy/UI tweak, no schema |
| M | Multi-screen + state, no/minimal schema |
| L | Schema + rules + multi-edge cases |

| Iter | Size |
|------|------|
| 7 | M |
| 8 | M |
| 9 | M |
| 10 | M |
| 11 | L |
| 12 | S–M |
| 13 | M |
| 14 | S–M |
| 15 | M |

---

# Open decisions (resolve before coding each iter)

| # | Decision | Options | Default suggestion |
|---|----------|---------|-------------------|
| D1 | Reset filters target | Login defaults vs Saved defaults | Match **Remember** flag behavior |
| D2 | Overdue from Dashboard | Status All + view All/For me | **All statuses** + current tab’s natural view |
| D3 | Undo restores reminder? | Yes if future / No | **No** (simpler) |
| D4 | Invite TTL | 48h / 7d | **7 days** |
| D5 | Recurrence model | Spawn on Done / pre-create series | **Spawn next on Done** |
| D6 | Overload threshold | 3 / 5 open | **3** |

---

# What we are not planning now

- Today / Later list sections  
- Full FCM server push  
- iOS  
- Chat / comments  
- Light theme  
- Complex RBAC beyond owner/member + creator permissions  
- Continuous automated QA (manual on request)  

---

# Next step (when you say go)

1. Confirm or change **D1–D6**.  
2. Start **Iteration 7** implementation only.  
3. After 7: update QA cases, then 8.

**Code freeze for this document:** plan only until you request implementation.

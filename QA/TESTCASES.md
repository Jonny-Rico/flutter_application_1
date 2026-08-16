# FamilyTasks — Test Cases v2.0

**App:** FamilyTasks (Flutter + Firebase)  
**UI:** English  
**Date:** 2026-08-16  
**Users (email only, no Google):**

| Role | Email | Notes |
|------|--------|--------|
| **A** | `qa.a.familytasks@example.com` | Owner / primary |
| **B** | `qa.b.familytasks@example.com` | Member / second account |

Passwords: `QA/test-accounts.local.md` (not in git).  
**Env:** Android emulator · Firestore rules deployed · iOS out of scope  

**Google Sign-In is out of this suite.** Linking Google is not tested.

**Result:** Pass · Fail · Blocked · Skip  

---

## 0. Smoke pack (P0)

`AUTH-P-01` `AUTH-P-02` `AUTH-P-03` `TASK-P-01` `TASK-P-04` `TASK-N-01` `FILT-P-01` `FAM-P-01` `FAM-P-03` `FAM-N-01` `PERM-N-01` `LOCK-P-02` `SET-P-01`

---

## 1. Auth (email)

### AUTH-P-01 · Sign in
**P0 · Happy**  
Pre: signed out.

| # | Step | Expected |
|---|------|----------|
| 1 | Open app | Login: **Sign in with Google**, **Sign in with email**, **Create account** |
| 2 | **Sign in with email** → A email/password → **Sign in** | **Tasks**; nav: Tasks, Family, Dashboard, Settings |

### AUTH-P-02 · Session after kill
**P0 · Session**  
Pre: A on Tasks.

| # | Step | Expected |
|---|------|----------|
| 1 | Force-stop app | — |
| 2 | Open again | Splash → **Tasks** (not Login) |

### AUTH-P-03 · Sign out
**P0**  
Pre: A signed in.

| # | Step | Expected |
|---|------|----------|
| 1 | Settings → **Sign out** | Login |
| 2 | Kill + open | Still Login |

### AUTH-P-04 · Switch A → B
**P1**  
Pre: A signed in.

| # | Step | Expected |
|---|------|----------|
| 1 | Sign out | Login |
| 2 | Sign in as B | Tasks; Settings shows **QA User B** / B email |

### AUTH-P-05 · Forgot password UI
**P1**  
Pre: Login.

| # | Step | Expected |
|---|------|----------|
| 1 | Sign in with email → **Forgot password?** | Reset form |
| 2 | Enter A email → **Send reset link** | Snackbar: *If an account exists for that email, we sent a reset link.* |

### AUTH-N-01 · Wrong password
**P0 · Negative**  
Pre: Login.

| # | Step | Expected |
|---|------|----------|
| 1 | Sign in with A email + wrong password | Stay on Login; error *Incorrect email or password*; no session |

### AUTH-N-02 · Unknown email
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Sign in `nobody@example.com` / any password | Stay on Login; friendly error; no crash |

### AUTH-N-03 · Validation on register
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | **Create account**, empty / name 1 char / password 7 chars / mismatch confirm | Validation errors; account not created |

### AUTH-N-04 · Duplicate email
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Create account with **A** email + new password | Error *An account already exists for this email* |

### AUTH-N-05 · Reset unknown email (no enumeration)
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Forgot password → `nobody@example.com` → send | Same success copy as AUTH-P-05 (no “user not found”) |

---

## 2. Email verification gate

QA A/B already verified. Gate cases use **fakes / a throwaway unverified user** in automation, not A/B.

### VER-P-01 · Verified user can create/join family
**P0**  
Pre: A verified, no group (or after leave).

| # | Step | Expected |
|---|------|----------|
| 1 | Family | Create / Join forms visible (not verify card) |

### VER-N-01 · Unverified cannot create/join
**P0 · Negative**  
Pre: test user with `emailVerified=false`.

| # | Step | Expected |
|---|------|----------|
| 1 | Open Family | No create/join; **Verify your email**; personal Tasks still work |
| 2 | (Optional) I have verified without clicking mail | Still gated |

### VER-N-02 · Unverified cannot use Family dashboard
**P1 · Negative**  
Same user: Dashboard → Family explains verify; no family stats.

---

## 3. App lock

### LOCK-P-01 · Enable + lock from background
**P0**  
Pre: A signed in, lock off.

| # | Step | Expected |
|---|------|----------|
| 1 | Settings → App lock ON → set 4-digit PIN twice | Lock enabled; stay in Settings (no PIN wall) |
| 2 | Home / app switch away → back | **App locked** |

### LOCK-P-02 · Unlock with PIN
**P0**  
Pre: lock on, locked screen.

| # | Step | Expected |
|---|------|----------|
| 1 | Enter correct PIN | Previous screen; app usable |

### LOCK-P-03 · Disable lock
**P1**  
Pre: lock on, unlocked.

| # | Step | Expected |
|---|------|----------|
| 1 | App lock OFF → confirm PIN | Toggle off; background no longer locks |

### LOCK-N-01 · Wrong PIN
**P0 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Enter wrong PIN | *Wrong PIN*; dots reset; still locked |

### LOCK-N-02 · Throttle after 5 failures
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | 5 wrong PINs | *Too many attempts. Try again in 30s*; keypad ignored until timer ends |

### LOCK-N-03 · Profile update does not lock
**P1 · Negative / regression**  
Pre: lock on, unlocked.

| # | Step | Expected |
|---|------|----------|
| 1 | Edit name (SET-P-01) | No lock screen |

---

## 4. Help

### HELP-P-01 · Open manual
**P1**  
Pre: A signed in.

| # | Step | Expected |
|---|------|----------|
| 1 | Settings → **Help** | In-app manual (EN default); chapters open |

### HELP-N-01 · Back closes Help
**P2 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | System back from Help | Settings; no crash |

---

## 5. Tasks

### TASK-P-01 · Create personal task
**P0**  
Pre: A, any group state.

| # | Step | Expected |
|---|------|----------|
| 1 | Tasks → + → title, save | Task in list (For me / All as per filters) |

### TASK-P-02 · Edit (creator)
**P1**

| # | Step | Expected |
|---|------|----------|
| 1 | Open own task → Edit → change title → save | List/detail show new title |

### TASK-P-03 · Detail + status
**P1**

| # | Step | Expected |
|---|------|----------|
| 1 | Open task → set In Progress / Done | Status updates; Done can Undo |

### TASK-P-04 · Checkbox Done + Undo
**P0**

| # | Step | Expected |
|---|------|----------|
| 1 | Checkbox Done | Snackbar + **Undo** |
| 2 | Undo within ~4s | Back to previous status |

### TASK-P-05 · Swipe Done / Delete
**P1**

| # | Step | Expected |
|---|------|----------|
| 1 | Swipe → Done | Same as mark Done + Undo |
| 2 | Swipe ← Delete → confirm | Task gone |
| 3 | Swipe ← Delete → cancel | Task remains |

### TASK-P-06 · Overdue badge
**P1**  
Pre: open task with past deadline (edit allows past date).

| # | Step | Expected |
|---|------|----------|
| 1 | View list | **Overdue** on open past-deadline row; not on Done |

### TASK-P-07 · Empty + Reset filters
**P0**  
Pre: A has ≥1 task; filters hide all.

| # | Step | Expected |
|---|------|----------|
| 1 | See empty + **Reset filters** | Filters restore; tasks visible |

### TASK-P-08 · Search
**P1**

| # | Step | Expected |
|---|------|----------|
| 1 | Search unique title | Only matches |
| 2 | Clear search | Full filtered list |

### TASK-N-01 · Create without title
**P0 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | New task, empty title, save | Blocked / validation; no empty task |

### TASK-N-02 · Delete cancelled
**P2 · Negative**  
Covered in TASK-P-05 step 3.

### TASK-N-03 · Past deadline allowed on edit
**P1** (was a product bug; now allowed)

| # | Step | Expected |
|---|------|----------|
| 1 | Edit overdue task deadline | Picker opens; can keep/change past date |

---

## 6. Recurrence

### REC-P-01 · Weekly spawn
**P0**  
Pre: A creates task Repeat **Weekly**, deadline set.

| # | Step | Expected |
|---|------|----------|
| 1 | Mark Done | Original Done; new To Do with deadline +7 days, same title |

### REC-P-02 · Daily / Monthly
**P1**  
Same for Daily (+1 day) and Monthly (+1 calendar month, clamp EOM).

### REC-P-03 · No repeat
**P2**

| # | Step | Expected |
|---|------|----------|
| 1 | Done on No repeat | No extra task |

### REC-N-01 · Undo deletes unedited next
**P0 · Negative / safety**

| # | Step | Expected |
|---|------|----------|
| 1 | Weekly Done → Undo immediately | Original not Done; spawned copy **gone** |

### REC-N-02 · Undo keeps edited next
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Weekly Done → edit spawned title → Undo original | Spawned copy **remains** |

---

## 7. Filters

### FILT-P-01 · Status filter
**P0**

| # | Step | Expected |
|---|------|----------|
| 1 | AppBar status → To Do / Done / All | List matches; chip label updates |

### FILT-P-02 · View filters with family
**P1**  
Pre: A in a group.

| # | Step | Expected |
|---|------|----------|
| 1 | For me / By me / Family / All | Pills visible; counts; list matches |

### FILT-P-03 · Remember ON
**P1**  
Settings Remember **ON**; set For me + To Do; leave Tasks; return → same.

### FILT-N-01 · View filters hidden without group
**P1 · Negative**  
Pre: A not in group.

| # | Step | Expected |
|---|------|----------|
| 1 | Tasks | No For me / Family pills (or equivalent hidden) |

### FILT-N-02 · Leave group resets Family view
**P1 · Negative**  
Pre: A in group, view **Family**.

| # | Step | Expected |
|---|------|----------|
| 1 | Leave group → Tasks | Not stuck on Family filter; no crash |

---

## 8. Family

### FAM-P-01 · Create group
**P0**  
Pre: A verified, no group.

| # | Step | Expected |
|---|------|----------|
| 1 | Family → name → **Create as owner** | Group exists; A is owner |

### FAM-P-02 · Generate invite
**P0**  
Pre: A owner.

| # | Step | Expected |
|---|------|----------|
| 1 | Invite → Generate | 6-char code; expiry shown |

### FAM-P-03 · B joins
**P0**  
Pre: valid unused code from A.

| # | Step | Expected |
|---|------|----------|
| 1 | B Family → Join with code | B is member; sees group |

### FAM-P-04 · Leave restores creator tasks
**P1**  
Pre: B in group; B created a personal-origin task (or any task B created).

| # | Step | Expected |
|---|------|----------|
| 1 | B Leave | B personal list has tasks B created; family-only tasks B didn’t create are gone for B |

### FAM-P-05 · Owner leave transfers ownership
**P1**  
Pre: A owner, B member.

| # | Step | Expected |
|---|------|----------|
| 1 | A Leave (others exist) | B becomes owner; group remains |

### FAM-P-06 · Dissolve (A alone)
**P1**  
Pre: only A in group.

| # | Step | Expected |
|---|------|----------|
| 1 | Dissolve | No group; A’s created tasks back as personal |

### FAM-N-01 · Invalid invite
**P0 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | B joins `XXXXXX` | Error; B has no group |

### FAM-N-02 · Reused code after join
**P0 · Negative**  
Pre: B already used the code.

| # | Step | Expected |
|---|------|----------|
| 1 | Same code again (or after regenerate) | Rejected |

### FAM-N-03 · Non-owner cannot invite
**P1 · Negative**  
Pre: B member.

| # | Step | Expected |
|---|------|----------|
| 1 | B opens Invite | No generate / *Only the group owner…* |

---

## 9. Permissions

### PERM-P-01 · A assigns personal task to B
**P0**  
Pre: same group.

| # | Step | Expected |
|---|------|----------|
| 1 | A creates personal, assignee B | B sees it under For me |

### PERM-P-02 · B can change status
**P1**  
B marks that task Done → allowed.

### PERM-N-01 · B cannot delete A’s task
**P0 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | B swipe-delete / detail delete | Hidden or permission error; task remains |

### PERM-N-02 · B cannot edit A’s title
**P1 · Negative**  
B opens task: title not editable (or save rejected).

---

## 10. Dashboard

### DASH-P-01 · My overview
**P1**  
Pre: A has tasks.

| # | Step | Expected |
|---|------|----------|
| 1 | Dashboard → My | Tiles Total/Open/Done/Overdue; tap count > 0 → Tasks with matching filter |

### DASH-P-02 · Family tab with group
**P1**  
Family stats + Share family summary opens share sheet.

### DASH-N-01 · Tap tile with 0
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Tap Overdue when 0 | Snackbar; Tasks not opened |

### DASH-N-02 · Family tab without group
**P2 · Negative**  
Empty + Go to Family; no crash.

---

## 11. Settings

### SET-P-01 · Edit name
**P0**  
Pre: A signed in.

| # | Step | Expected |
|---|------|----------|
| 1 | Pencil → new name (≥2) → Save | Settings + Family members show new name |

### SET-P-02 · Remember filters ON/OFF
**P1**  
ON: filters persist. OFF: next Tasks open uses All / All statuses (per product).

### SET-P-03 · Notify toggle
**P1**  
ON/OFF persists after reopen Settings.

### SET-P-04 · Haptics toggle
**P2**  
OFF: Done/Delete no vibration. ON: pulse.

### SET-P-05 · Sign-in methods (email user)
**P1**  
A: Email and password **Linked**; Google **Not linked** + Link (Link itself not executed in this suite).

### SET-N-01 · Name too short
**P1 · Negative**

| # | Step | Expected |
|---|------|----------|
| 1 | Edit name to 1 character → Save | Error; name unchanged |

### SET-N-02 · Add email when already linked
**P2 · Negative**  
Add is hidden (already Linked). No second password provider.

---

## 12. Notifications (local)

### NOTIF-P-01 · Reminder “In 1 hour”
**P1**  
Create task + reminder → no crash; reminder scheduled (automation: service called).

### NOTIF-P-02 · New task alert for assignee
**P1**  
A assigns to B; B has Notify ON and app/sync → local alert (or scheduler invoked).

### NOTIF-N-01 · Notify OFF
**P1 · Negative**  
B Notify OFF; A assigns → no new-task alert for B.

### NOTIF-N-02 · No self-notify
**P1 · Negative**  
A creates task for self → A does not get “new task” alert.

---

## 13. Stability

### STAB-P-01 · Rapid tab switching
**P2**  
Hammer Tasks/Family/Dashboard/Settings → no crash.

### STAB-N-01 · Offline create
**P2 · Negative**  
Airplane → create task: offline handling or error; no crash. Sync when back if applicable.

---

## Counts

| Area | Positive | Negative | Total |
|------|----------|----------|-------|
| Auth | 5 | 5 | 10 |
| Verification | 1 | 2 | 3 |
| App lock | 3 | 3 | 9 |
| Help | 1 | 1 | 2 |
| Tasks | 8 | 3 | 11 |
| Recurrence | 3 | 2 | 5 |
| Filters | 3 | 2 | 5 |
| Family | 6 | 3 | 9 |
| Permissions | 2 | 2 | 4 |
| Dashboard | 2 | 2 | 4 |
| Settings | 5 | 2 | 7 |
| Notifications | 2 | 2 | 4 |
| Stability | 1 | 1 | 2 |
| **Sum** | **42** | **30** | **72** |

Smoke P0: 13 cases.

---

# Automation plan (100% of this suite)

**No Google.** Only A/B email (+ one unverified fixture for VER-*).

### Layers

| Layer | Runner | Use for |
|-------|--------|---------|
| **unit** | `flutter test test/unit` | Domain: overdue, permissions, recurrence dates, invite valid, PIN hash |
| **widget** | `flutter test test/widget` | One screen + fakes (`ProviderScope` overrides) |
| **e2e** | `integration_test` + emulator | Real Firebase + A/B: session, family join, leave restore, switch user |

### ID → layer

| IDs | Layer |
|-----|--------|
| AUTH-N-03, TASK-N-01, SET-N-01, REC dates, PERM canDelete/canEdit | **unit** (and widget where UI) |
| AUTH-P-01…04, AUTH-N-01/02/04/05, LOCK-*, HELP-*, TASK-*, FILT-* (single user), SET-*, DASH-N-*, VER-N-* (fake user), STAB-P-01 | **widget** with fakes |
| AUTH-P-01/02/03/04, FAM-P-01…06, FAM-N-01/02/03, PERM-*, FILT-N-02, DASH-P-*, NOTIF-P-02 / N-* (scheduler spy or e2e), STAB-N-01 | **e2e** on emulator |

Many IDs have **both** widget (fast) and e2e (one smoke). **100% = every ID has ≥1 automated test.** Prefer widget; e2e only when two users or process kill or real Auth.

### Unverified user (VER-*)
Do **not** use A/B. In widget: fake `emailVerifiedProvider = false`. In e2e: create `qa.unverified+time@example.com` via Auth API, never verify, delete after (or leave in project).

### Secrets
```
--dart-define=QA_A_EMAIL=qa.a.familytasks@example.com
--dart-define=QA_A_PASSWORD=...
--dart-define=QA_B_EMAIL=qa.b.familytasks@example.com
--dart-define=QA_B_PASSWORD=...
```
Never commit passwords.

### Implementation order
1. Fakes + fix default `widget_test` + unit permissions/recurrence.  
2. Widget: Login, Tasks, Filters, Settings, Lock (fake session), Help, VER gate.  
3. `integration_test/smoke_test.dart`: AUTH-P-01/02/03, TASK-P-01, FAM-P-01+03, FAM-N-01, PERM-N-01.  
4. Rest of e2e: leave restore, dissolve, REC-N-01 on device, FILT-N-02.  
5. NOTIF: spy on `TaskNotificationService` in widget = pass for suite; optional 1 e2e.  
6. CI: PR = unit+widget; nightly = e2e smoke.

### Cleanup
E2e must delete groups/tasks created in the run (or prefix titles `autotest-`). A/B stay; no extra permanent users except optional unverified.

### Out of automation-by-design
- Google picker / Link Google  
- Real inbox / password-reset mail delivery  
- iOS, FCM, 10-member cap (optional later)  
- Waiting 1 hour for a reminder to fire (assert schedule only)

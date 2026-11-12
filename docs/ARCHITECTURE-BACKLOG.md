# FamilyTasks — Architecture backlog

**Status:** Iteration 20 is done. 17–19 and 21 stay planned.  
**Source:** Architecture review of iterations 7–16 (code on `main`) plus uncommitted Shop/Notes.  
**Date:** 2026-11-12  
**Depends on:** `docs/PRODUCT-BACKLOG.md` iterations 7–16, which are already committed and pushed.  
**Env:** Android. Firestore rules deployed with the same commit as the app change. iOS out of scope.

---

## Why this backlog exists

The feature split, repositories, and Riverpod providers stay. Two boundaries are weaker than the UI:

1. Firestore rules allow a verified user who knows a `groupId` to join that group without an invite, and they allow any signed-in user to read member emails.
2. Join, leave, and dissolve are several writes. Personal tasks are copied into the family with no prompt. A failed copy is logged and dropped.

Shop and Notes are implemented locally. Their rules are already deployed, but the feature is not on `main`.

---

## Goals

| Goal | How we measure |
|------|----------------|
| A family can be entered only through create or a valid invite | Rules deny self-insert into `members` |
| Member list and emails stay inside the family | Rules deny member reads for outsiders |
| The app and the rules agree who the owner is | Owner actions use `groups.ownerId` / member role |
| Join cannot exceed 10 people | `memberCount` checked in the same transaction and in rules |
| Personal tasks stay private until the user agrees | Create/join does not copy tasks |
| Shop, Notes, and rules ship together | `main` contains the feature and the matching `firestore.rules` |

---

## Decisions (locked for this backlog)

| # | Decision | Choice |
|---|----------|--------|
| **D7** | Where membership is enforced | Client transaction **and** rules. No Cloud Function unless one leave/dissolve needs more than 500 writes |
| **D8** | Personal tasks on join/create | Do **not** copy them. After the group exists, one prompt; default is **leave them personal** |
| **D9** | Tasks on leave | Tasks this user **created** return to `users/{uid}/tasks`. Tasks created by others stay in the group. The confirm dialog says so |
| **D10** | Shop data | No automatic move. Personal list stays under the user. Need, plans, and trips are family data only when a group exists |
| **D11** | Bottom navigation | Five slots: **Tasks, Shop, Family, Dashboard, Notes**. No More tab. Settings and Log Out open from the menu button on the left of each of those root screens |
| **D12** | Assignee edit flags | Remove `assigneeCanEdit` / `assigneeCanDelete`. Creator edits fields. Any member may change status of a family task. This matches the app today |

---

## Principles

1. Rules are the boundary. A changed client must not be able to do more than the honest app.
2. One iteration is demoable on the Android emulator and covered in `QA/TESTCASES.md`.
3. Deploy `firestore.rules` in the same change as the code that needs them. Do not deploy ahead of `main`.
4. UI copy stays English.
5. Do not add a sync engine, FCM, iOS, a light theme, chat, or roles beyond owner/member.
6. Keep repositories and Riverpod. Do not add a use-case layer.

```text
17 Rules ──► 18 Explicit task move ──► 19 Atomic membership
        └──► 20 Shop + Notes + avatar Settings
17 Rules ──► 21 Remove dead permission flags
```

**20 is first**, by request. 17 still comes before 18 and 19. 19 is safer after 18, so the join transaction no longer contains a task copy. 21 is independent after 17.

---

# Iteration 17 — Membership rules match the app

**Theme:** «В группу нельзя войти, зная только id»  
**Size:** M  
**Includes:** rules, the small client writes those rules require, owner check in the UI, rules tests

## Epic E17.1 — Invite is required to become a member

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-17.1.1** | As a verified user, I can join only with a valid pending invite | Join writes `inviteCode` on the new member doc. Rules allow that create only when the invite exists, is `pending`, `groupId` matches, not expired, and `memberId == auth.uid` | P0 |
| **US-17.1.2** | As a verified user, I cannot insert myself into a group I only know by id | Direct create of `groups/{id}/members/{uid}` without that invite is denied | P0 |
| **US-17.1.3** | As the creator, I become the owner without an invite | Group create allows the owner member doc only when `groups.ownerId == auth.uid` and the member role is `owner` | P0 |

## Epic E17.2 — Private member list and a consistent role

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-17.2.1** | As a non-member, I cannot read a family's members | `members` read and list require membership. Emails are not readable from outside | P0 |
| **US-17.2.2** | As a user, I cannot assign myself a family or a role | `users/{uid}` may change `groupId` / `groupRole` only when the member doc after the write agrees. Clearing them is allowed when the member doc is removed in the same commit | P0 |
| **US-17.2.3** | Owner actions follow the group document | Family screen, invite, dissolve, and remove use `groups.ownerId` (or the member role that matches it), not a `groupRole` the user could have written alone | P0 |
| **US-17.2.4** | Task authorship is the signed-in user | Group and personal task creates require `createdBy == auth.uid`, except the existing owner restore onto a member's personal tasks | P0 |

## Iteration 17 — Out of scope

- Member cap in rules (needs `memberCount`, iteration 19)
- Opt-in task migration (iteration 18)
- Shop/Notes nav (iteration 20)
- Deleting `TaskPermissions` (iteration 21)

## Iteration 17 — Definition of Done

- [ ] Honest create, join, leave, and dissolve still succeed
- [ ] Rules tests deny self-join, outsider member reads, forged `groupRole`, and forged `createdBy`
- [ ] `QA/TESTCASES.md` has the negative cases
- [ ] Rules file in git matches what is deployed

## Iteration 17 — Demo script

1. User B joins with A's code and lands in the family.
2. A second client call that only writes `members/{B}` on A's group fails.
3. B opens Family and cannot invite or dissolve.

---

# Iteration 18 — Personal tasks move only by choice

**Theme:** «Мои старые задачи не становятся семейными сами»  
**Size:** M  
**Depends on:** 17

## Epic E18.1 — No silent copy

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-18.1.1** | As a user who creates or joins a family, my existing personal tasks stay mine | `createGroup` and `joinGroup` do not write those tasks into `groups/{id}/tasks` | P0 |
| **US-18.1.2** | As that user, I can move them in one step | After create/join, one prompt: **Move personal tasks into the family?** Primary **Keep personal**, secondary **Move**. Default path is keep | P0 |
| **US-18.1.3** | Move copies the current personal set once | Move writes each personal task into the group and deletes the personal doc. Failure shows an error and does not claim success. A second prompt does not duplicate tasks already moved | P0 |

## Epic E18.2 — Leave copy and shop behavior stay clear

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-18.2.1** | As a member who leaves, I know which tasks come with me | Confirm dialog states that tasks **you created** return to your personal list and other family tasks stay. Behavior matches **D9** | P0 |
| **US-18.2.2** | Shop lists do not follow the task move | Need, plans, and trips are family collections when a group exists. The personal shop list stays under the user. Join does not copy shop docs. Help EN/RU says this in one sentence | P1 |

## Iteration 18 — Out of scope

- Changing recurrence, filters, or dashboard math
- A shop "move into family" action

## Iteration 18 — Definition of Done

- [ ] Create and join leave personal tasks in place unless the user taps Move
- [ ] Leave dialog matches D9
- [ ] Help EN/RU updated
- [ ] QA cases for keep and move

## Iteration 18 — Demo script

1. User with two personal tasks creates a family and taps **Keep personal**. Family task list does not show them.
2. Repeat with **Move**. Both tasks show for the family.
3. Leave as owner-with-successor. The dialog names the rule; created tasks are personal again.

---

# Iteration 19 — Join, leave, and dissolve are one commit

**Theme:** «Состав семьи не рвётся посередине записи»  
**Size:** L  
**Depends on:** 18, so the transaction does not also copy tasks

## Epic E19.1 — Counter and transaction

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-19.1.1** | As the app, membership changes one family in a single transaction | Join, leave, owner handoff, and dissolve each use one Firestore transaction for member docs, `users.groupId` / `groupRole`, invite status, and `groups.memberCount` | P0 |
| **US-19.1.2** | As a family, we cannot grow past 10 | `memberCount` increments and decrements with member create/delete. Rules reject a count above `AppConstants.maxGroupMembers` or a count that does not match the member write | P0 |
| **US-19.1.3** | A failed write does not look successful | Permission errors and conflicts surface in the UI. The repository does not log-and-return on `permission-denied` | P0 |

## Epic E19.2 — Batches that do not fit

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-19.2.1** | Leave still restores created tasks when there are many | Task restore may be a follow-up batch chunked under 500 writes. If a chunk fails, the user sees the error and can retry. Membership itself is already committed | P1 |

## Iteration 19 — Out of scope

- Cloud Functions
- Moving another member's tasks
- Shop or note migration

## Iteration 19 — Definition of Done

- [ ] Two joins racing for the last seat: one succeeds, one gets a clear full-group error
- [ ] Rules tests cover count 10 and a forged `memberCount`
- [ ] QA cases updated
- [ ] Rules deployed with the commit

## Iteration 19 — Demo script

1. Fill a group to 10. The next invite join fails with the full-group message.
2. Owner leaves with a successor. One new owner, leaver has no group.
3. Owner dissolves an empty-of-others group. Members and group doc are gone.

---

# Iteration 20 — Shop, Notes, and the settings avatar

**Theme:** «Пять разделов снизу, настройки — аватар слева»  
**Size:** M  
**Depends on:** none for the UI. Rules for Shop/Notes still ship in the same commit as the feature. Started before 17 by request.

The Shop and Notes code, tests, and design mockups already exist in the working tree. This iteration lands them. It does not redesign the lists.

## Epic E20.1 — One commit for the feature and the rules

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-20.1.1** | Shop and Notes work for a signed-in user | Need, plans, personal list, trip, notes, and note share behave as in the current local build | P0 |
| **US-20.1.2** | Rules match that build | Group `needItems`, `shopTrips`, and `planItems` are member-only. User subcollections are self-only. Note create-for-share stays limited to the same family, `sharedBy == auth.uid`, and `ownerId` of the target | P0 |
| **US-20.1.3** | `main` and Firebase match | The commit contains `lib/features/shop`, `lib/features/notes`, router, shell, tests, and `firestore.rules`. Deploy that file. No extra matches live only on the server | P0 |

## Epic E20.2 — Five tabs, settings on the avatar

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-20.2.1** | As a user, the bar stays the five sections | Bar is **Tasks, Shop, Family, Dash, Notes** | P0 |
| **US-20.2.2** | As a user, I open Settings or log out from the menu | Each root screen shows a menu button on the left. The title is centered and bold. Tap opens **Settings** and **Log Out**, each with a small icon. Log Out signs out and the router shows Login. Family no longer has a settings gear; Invite stays on the right for the owner | P0 |

## Iteration 20 — Out of scope

- New shop or note features beyond the working tree
- Moving shop data on join (see D10)
- iOS

## Iteration 20 — Definition of Done

- [x] Working tree feature is committed; `git status` clean for these paths
- [x] Widget tests for shop and notes pass
- [x] QA cases for shop hub, a trip, a note, and share
- [x] Rules deployed. Confirmed already live; this commit contains the same `firestore.rules`
- [x] Manual smoke of the five-tab bar and the menu on each root screen

## Iteration 20 — Demo script

1. On Tasks, open the menu on the left and tap Settings. Settings opens. Back returns to Tasks.
2. The same menu is on Shop, Family, Dashboard, and Notes. Family's right side has Invite only for the owner.
3. Open Shop, add a need, start a trip, check an item.
4. Open Notes, write a note, share it to the other member.

---

# Iteration 21 — One permission story for tasks

**Theme:** «В модели нет флагов, которые приложение не использует»  
**Size:** S  
**Depends on:** 17

## Epic E21.1 — Remove the unused flags

| ID | User story | Acceptance criteria | Pri |
|----|------------|---------------------|-----|
| **US-21.1.1** | Field edits stay with the creator | `canEditFields` is `createdBy == userId`. `assigneeCanEdit` and `assigneeCanDelete` are removed from the model, writes, and rules if present | P0 |
| **US-21.1.2** | Family status stays shared | Any member can still change status of a family task. An assignee can still change status of a personal task assigned to them. Rules stay aligned with that | P0 |
| **US-21.1.3** | Help does not promise the removed flags | EN/RU help describes creator-edits and shared family status, if it mentioned assignee edit rights | P1 |

## Iteration 21 — Definition of Done

- [ ] No remaining `assigneeCanEdit` / `assigneeCanDelete`
- [ ] Existing task permission unit tests updated and passing
- [ ] QA permission cases still match the dialogs

## Iteration 21 — Demo script

1. Member opens a family task they did not create: status changes, title does not.
2. Creator edits the title.

---

# Cross-cutting

| ID | Item | When |
|----|------|------|
| **XC-5** | Rules tests run with the Firebase emulator | Start in 17, extend in 19 |
| **XC-6** | Deploy rules only from the commit that contains them | Every iteration that touches `firestore.rules` |
| **XC-7** | QA cases per iteration | Each DoD |

---

# Priority stack

1. **20** — Shop, Notes, account menu (done)  
2. **17** — Membership rules  
3. **18** — Opt-in task move  
4. **19** — Transaction and member cap  
5. **21** — Remove dead permission flags

---

# Out of scope

- Cloud Functions, until a real batch passes 500 writes  
- Custom offline sync  
- FCM, iOS, light theme, chat, Today/Later  
- Roles other than owner and member  
- Server-timestamp sweep of existing task writes  
- Reworking repository or Riverpod structure  

---

# Next step

1. **Iteration 17** — membership rules.

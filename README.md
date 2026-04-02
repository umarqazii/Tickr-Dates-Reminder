# Tickr

A **local-first** Flutter app for remembering important dates—birthdays, anniversaries, and one-off events. Data lives on-device in **Isar**, syncs to **Supabase** in the background when you’re signed in with **Google**, and uses **local notifications** for upcoming reminders.

## Features

- **Upcoming** list grouped by today, this week, later, and past; yearly events show which anniversary is next.
- **Calendar** view with markers and a per-day event list.
- **Google sign-in** via Supabase Auth; sign-out clears the local database and Google session so switching accounts does not leak another user’s events.
- **Theming** via `lib/core/theme/` (`AppColors`, `AppTheme`).

## Tech stack

| Area        | Choice                          |
|------------|----------------------------------|
| UI / state | Flutter, Riverpod               |
| Local DB   | Isar 3                          |
| Backend    | Supabase (Postgres + Auth)      |
| Sign-in    | `google_sign_in`                |
| Reminders  | `flutter_local_notifications`   |

## Getting started

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and clone this repo.
2. Install dependencies and generate Isar code:

   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Configure **Supabase** (URL + anon key) and **Google OAuth** (web client ID) in your app entrypoint—see `lib/main.dart` and `lib/features/auth/presentation/auth_controller.dart` / `login_screen.dart`. Your Supabase project needs a `tickr_events` table and RLS policies scoped to `auth.uid()`.
4. Run the app:

   ```bash
   flutter run
   ```

## Project layout (high level)

- `lib/main.dart` — app bootstrap, Supabase init, `ProviderScope`.
- `lib/core/` — database, sync, notifications, theme.
- `lib/features/auth/` — login and auth providers.
- `lib/features/events/` — domain model, repository, UI (list, calendar, add/edit sheet).

---

Tickr is a personal project; adjust credentials and schema for your own Supabase project before shipping.

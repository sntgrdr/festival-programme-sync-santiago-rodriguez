# Festival Programme Sync

Rails 8 app that replaces the old ad-hoc nightly script with a resilient, idempotent sync of screenings/films/venues from an external festival-management system, plus a Hotwire-driven filtered screenings list.

See `ASSIGNMENT.md` for the original brief and setup instructions.

## What I'd do differently with more time

With more time, I'd address the security gap first: the Sidekiq dashboard and the `/sync_runs` page I added, would both sit behind Rails 8's built-in auth and a manual "force sync" button on the report page just for specific scenarios. I'd also revisit two design decisions that hold at this data volume but wouldn't at scale: `ScreeningSync` upserts row-by-row which is fine for dozens of records, but `upsert_all` would be needed for thousands, and `ScreeningDeletion` infers removals via a `NOT IN` clause over every seen `external_id`, which degrades badly with a large dataset and could hit query-size limits. The more scalable fix would be flagging each synced row with a dedicated `last_synced_at` timestamp and deleting anything older than the run's start. It wasn't implemented because it conflicts with the dirty-tracking I use for accurate created/updated counters (`updated_at` deliberately isn't touched when nothing changed), and untangling that tradeoff felt out of scope for this exercise's actual data size. I'd also reconsider `sidekiq-cron` over self-rescheduling if the schedule needed to survive a full Sidekiq restart.

## What I changed in the existing code, and why

A few things in the given code needed fixing. `venue_sync.rb` matched venues by `name` instead of `external_id`. The screenings filter silently ignored the `q` search param, N+1'd films/venues in the view. None of the `bin/*` scripts had their executable bit set, so the app couldn't boot at all. `config.hosts` didn't permit the internal Docker hostname `web`, which silently blocked `ScreeningSync` from ever reaching the mock API outside of tests.

## Assumptions I made

A few assumptions shaped the design. Deletions are only inferred from a run that fetched every page successfully. `generation`, `fail_after` and `slow` are treated purely as mock-API test knobs, not real parameters: production usage is a plain `ScreeningSync.new.call` with no arguments. The auto-reschedule interval is a somewhat arbitrary one hour.

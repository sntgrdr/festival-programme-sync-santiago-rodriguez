# Festival Programme Sync

Rails 8 app that replaces the old ad-hoc nightly script with a resilient, idempotent sync of screenings/films/venues from an external festival-management system, plus a Hotwire-driven filtered screenings list.

See `ASSIGNMENT.md` for the original brief.

## Running it

Everything runs in Docker. One step:

```bash
docker compose up --build
```

That starts Postgres, Redis, the Rails web server, a Tailwind watcher and Sidekiq, and creates/migrates/seeds the database on first boot.

- App: <http://localhost:3000>
- Sidekiq dashboard: <http://localhost:3000/sidekiq>
- Postgres is exposed on host port **5544**

```bash
make console   # rails console inside the web container
make test      # run the RSpec suite
make sh        # a shell in the web container
```

## Running the sync manually

```ruby
# in `make console`
ScreeningSync.new.call
SyncRun.last
```

## What I'd do differently with more time

## What I changed in the existing code, and why

## Assumptions I made

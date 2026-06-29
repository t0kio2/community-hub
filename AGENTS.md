# Repository Instructions

## Rails / Backend Commands

Run Rails commands for this repository through Docker Compose. Do not use the host Ruby for backend tests, runners, migrations, or console commands unless the user explicitly asks for it.

Use the running backend service when available:

```sh
docker compose exec backend bin/rails test ...
docker compose exec backend bin/rails runner ...
docker compose exec backend bin/rails db:migrate
```

For test runs, make sure the command uses the test environment and test database, for example:

```sh
docker compose exec -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test ...
```

If the test database needs preparation:

```sh
docker compose exec -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails db:prepare
```

---
name: plan-doc-implement-test
description: Use when Codex is asked to implement, modify, fix, or add tests in this repository and should follow the team's workflow: write or update a concrete plan/design document before implementation, implement the change, add or update tests, and write comments and test case names/descriptions in Japanese.
---

# Plan, Document, Implement, Test

## Workflow

For implementation work in this repository, follow this sequence.

1. Inspect the relevant code and docs first.
2. Write or update a concrete plan/design document before editing production code.
3. Implement the change.
4. Add or update tests for the changed behavior.
5. Run the focused tests, and run broader tests when the change has shared impact.
6. Report the changed files, test command, and result.

## Planning Document

Prefer an existing relevant document when one clearly exists.

If no suitable document exists, create one under `docs/` with a descriptive name. Avoid date-only filenames for design documents.

Use `docs/tasks/` only for short-lived task notes. Use `docs/` for reusable design, workflow, and operation documents.

The plan should be concrete enough for another developer to implement from it:

- goal and background
- affected files or modules
- data model or API changes
- implementation steps
- validation and test plan
- known tradeoffs or follow-up work

Keep the document concise. Update it as decisions change during implementation.

## Implementation

Keep changes scoped to the documented plan unless the code reveals a necessary adjustment.

When the implementation differs from the plan, update the document instead of leaving it stale.

Prefer existing project patterns over new abstractions.

When writing HTML, place `<style>` tags at the bottom of the HTML.

## Tests

Add or update tests with the implementation.

Cover both the success path and important failure/rollback paths when behavior spans multiple records or services.

For this Rails project, prefer Docker Compose for Rails tests unless a working local Ruby 3.3 environment is already available.

Use focused commands first, for example:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test path/to/test_file.rb
```

If the test database is missing, prepare it first:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails db:prepare
```

## Japanese Comments And Tests

Write newly added code comments in Japanese.

Write test case names, test descriptions, and explanatory test comments in Japanese.

Do not translate framework-required identifiers or API names. Keep class names, method names, route names, constants, and command names in their normal project language.

Avoid adding comments unless they clarify non-obvious behavior.

# Pragmatic

## AI Disclosure

This project utilized AI assistance; [Kimi](https://www.kimi.com/) (UI version) was the chosen tool. Its use was limited to:

- Providing text and ideas for the base prototype (view text and messages);
- Corrections and suggestions for code comments;
- Translation corrections and internationalization (i18n) improvements;
- Suggesting potential errors and issues (with the help of Google Search);
- Correcting commit messages (using Conventional Commits);
- Generating templates for issues and pull requests, along with their respective text.
- Text adjustments for this README itself;

> An important note here: Since I already use daisy-ui (a frontend dependency) for development, I utilized some structures I had previously created, and certain parts were built using other AIs. My focus here was not to demonstrate how to write screens from scratch, but rather to reuse existing components to accelerate the prototyping process.

## Setup

The only supported method is via Docker.

> Other setups (local Ruby with mise, rbenv, etc.) may work but are not currently supported.

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) 29.7 or higher
- [Docker Compose](https://docs.docker.com/compose/install/) 5.5 or higher

Check using `docker version` and `docker compose version`.

### First steps

```sh
git clone git@github.com:ricardopacheco/pragmatic.git pragmatic
cd pragmatic
bin/setup
```

### Running in development environment

```sh
docker compose --profile dev up
```

It starts up two services: `server` (Rails at <http://localhost:3000>) and `frontend` (Tailwind in watch mode).

> Upon initial startup, the database is created, migrated, and seeded, which takes a few seconds before the server becomes available; the various `Done in …ms` messages from the `frontend` during this interval are harmless.

Seeded accounts (password `password` for all):

| E-mail                 | Papel  |
|------------------------|--------|
| `admin@pragmatic.dev`  | Admin  |
| `user@pragmatic.dev`   | User   |

> Rebuild (`docker compose --profile dev build`) when you change the `Gemfile` or the `Dockerfile`.

### Run the tests

```sh
docker compose --profile test run --rm --build test
```

Runs the full `bin/ci` process: linting (Standard), quality checks (RubyCritic), security audits
(bundler-audit, importmap audit, Brakeman), the test suite, system tests in
headless Chromium, and a coverage check (100% line coverage required).

The test image loads a copy of the code, which is why `--build` is used after every change. To
run only a specific part, pass the command:

```sh
docker compose --profile test run --rm --build test bin/rails test test/models/user_test.rb
docker compose --profile test run --rm --build test bin/rails test:system
```

The coverage report is generated inside the container; to open it in your browser, copy it
out before discarding the container:

```sh
docker compose --profile test run --build --name pragmatic-test test
docker cp pragmatic-test:/usr/src/app/coverage/. ./coverage
docker rm pragmatic-test
```

then open `coverage/index.html`.

## Decisions and limitations

- **Realtime**: Hotwire with Stimulus, for the sake of simplicity. Inertia.js would be interesting if our app required complex frontend elements.
- **Database**: SQLite instead of Postgres. A practical approach with fewer dependencies.
- **Frontend**: Use Tailwind CSS with daisyUI, as this dependency offers robustness for our scenario with minimal to no JavaScript (real-time server-side);
- **Docker profiles**: Keep the Docker files to a minimum. While passing additional parameters adds complexity, I opted for simplicity and fewer files ("less is more").
- **JIT**: The Docker image enables Ruby 4's ZJIT (`RUBY_ZJIT_ENABLE=1`) across all
processes. The [Ruby 4.0 announcement](https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/)
recommends holding off on ZJIT in production until version 4.1; to revert to YJIT,
leave `RUBY_ZJIT_ENABLE` unset in the environment, and Rails will enable YJIT
automatically in production.
- **Unencrypted email**: Sensitive session columns (IP, user agent) are encrypted;
the email field is not, because partial matching (`LIKE`) and unique indexes
do not work on encrypted values. It is excluded from logs via `filter_parameters`.
- **Upload-only avatars**: While the requirements allowed for uploads or remote URLs,
only uploads are supported (using Active Storage, with variants and validation
for type, size, and content).
- **Docker-only setup**: This is the tested path; local Ruby environments (mise, rbenv)
are not supported.
- **Per-clone credentials**: `bin/setup` generates a local `master.key` and
`credentials.yml.enc`; neither is committed to Git, and the CI generates its own.
- **System tests across two browsers**: The CI runs the system test suite on Chrome
and Firefox; locally, the browser is selected via `SYSTEM_TEST_BROWSER=headless_firefox`.
- **Security tested, not just configured**: `test/integration/security_test.rb` covers XSS,
SQL injection, and CSRF; public write actions (login, sign-up, password reset)
are rate-limited. Brakeman runs in `bin/ci` and fails on any warning.
- **WAL**: It is enabled by default by the Rails 8 adapter; you can override this using pragmas — such as `{ journal_mode: delete }` in `database.yml`— but I do not recommend it, as without WAL, every write blocks reads.
- **Application Exceptions**: TrackExceptionService centralizes reporting and delegates to Rails.error; in development, it goes to the log, and Sentry/Honeybadger can be integrated simply by subscribing to the reporter, without modifying the code that reports the exception.


## Troubleshooting

- **`AEAD authentication tag verification failed` when starting the containers.**
The container received a key different from the one used to encrypt `config/credentials.yml.enc`.
Docker Compose reads the `.env` file, but a shell-exported variable takes precedence over it—usually an
old `export RAILS_MASTER_KEY=...` still active in the terminal (or in `.bashrc`/`.zshrc`).
Check it with `echo $RAILS_MASTER_KEY`; if it outputs something, run `unset RAILS_MASTER_KEY` and start the containers again.
- Rubycritic does not show test coverage in the reports. This is an unresolved issue due to test suite parallelization. To view it while bypassing this limitation, you can use:

```sh
docker compose --profile test run --build --name pragmatic-cov -e PARALLEL_WORKERS=1 test bash -c "bin/rails db:prepare && bin/rails test && bin/rails test:system && bin/rubycritic -f html"
docker cp pragmatic-cov:/usr/src/app/tmp/rubycritic/. ./tmp/rubycritic
docker rm pragmatic-cov
```

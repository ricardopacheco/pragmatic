# syntax=docker/dockerfile:1
# check=error=true

# Three targets live here:
#
#   docker build -t pragmatic .                          production (the default, last stage)
#   docker build --target development -t pragmatic-dev . the app with every gem group, code mounted
#   docker build --target test -t pragmatic-test .       the suite, with a browser
#
# Or through compose, which wires the ports, the volumes and the master key:
#
#   docker compose --profile app up
#   docker compose --profile dev up
#   docker compose --profile test run --rm test
#
# RUBY_VERSION is pinned here and in the Gemfile ("ruby 4.0.6"); this project has no
# .ruby-version file.
ARG RUBY_VERSION=4.0.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base
WORKDIR /usr/src/app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl file libjemalloc2 libvips sqlite3 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Throw-away build stage to reduce size of final image
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times.
# -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Development image
FROM build AS development

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

RUN bundle install

# A non-root user, for parity with the other targets.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /usr/src/app
USER 1000:1000

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]


# Test image.
FROM build AS test

# Chromium for the system tests. Debian packages the driver separately, and Selenium looks for a
# binary named google-chrome, hence the symlink.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y chromium chromium-driver && \
    ln -s /usr/bin/chromium /usr/bin/google-chrome && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# SYSTEM_TEST_CHROME_NO_SANDBOX is read by test/application_system_test_case.rb. chromium-sandbox
# is only a recommended package, so --no-install-recommends above leaves the SUID helper out and
# Chromium exits at startup. The flag lives here, not in the test code, so that running the suite
# outside a container keeps the sandbox on.
ENV RAILS_ENV="test" \
    BUNDLE_WITHOUT="" \
    SYSTEM_TEST_CHROME_NO_SANDBOX="1"

RUN bundle install

# Chromium will not run its sandbox as root, and these tests drive a real browser.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /usr/src/app
USER 1000:1000

CMD ["bin/ci"]

# Final stage for app image.
FROM base AS production

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Copy built artifacts: gems, application
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /usr/src/app /usr/src/app

# Entrypoint prepares the database.
ENTRYPOINT ["/usr/src/app/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]

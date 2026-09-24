# Run using bin/ci

CI.run do
  # Was bin/setup --skip-server, which also installed gems and started a server. With Docker as the
  # supported flow the gems come baked into the image, so all the pipeline still needs is a database.
  step "Setup", "bin/rails db:prepare"

  step "Style: Ruby", "bin/standardrb"
  step "Quality: RubyCritic", "bin/rubycritic"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
  step "Tests: System", "bin/rails test:system"
  step "Tests: Coverage", "bin/coverage"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end

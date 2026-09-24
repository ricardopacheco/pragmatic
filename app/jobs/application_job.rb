class ApplicationJob < ActiveJob::Base
  # Operations enqueue jobs inside transactions: hold the enqueue until the commit,
  # otherwise a worker can pick the job up before the records exist.
  self.enqueue_after_transaction_commit = true

  MAX_RETRIES = 15

  # Only the last failure is reported, and raised again so the queue keeps the job as failed.
  retry_on StandardError, attempts: MAX_RETRIES do |job, error|
    job.capture_exception(error)

    raise error
  end

  DASHBOARD_STREAM = "admin_dashboard"
  USERS_STREAM = "admin_users"
  IMPORTS_STREAM = "admin_imports"

  def capture_exception(error)
    TrackExceptionService.capture_exception(error, job: self.class.name, job_id:, executions:)
  end

  # Refreshes carry the id of the request that caused them, so Turbo skips the tab
  # that made the change: it already shows the new page, flash message included.
  def refresh(stream, request_id)
    Turbo.with_request_id(request_id) { Turbo::StreamsChannel.broadcast_refresh_to(stream) }
  end

  def broadcast_dashboard
    Turbo::StreamsChannel.broadcast_replace_to(
      DASHBOARD_STREAM,
      target: "dashboard_stats",
      partial: "admin/dashboards/stats",
      locals: {dashboard: Admin::DashboardDecorator.new}
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      DASHBOARD_STREAM,
      target: "recent_users",
      partial: "admin/dashboards/recent_users_list",
      locals: {users: Admin::UserDecorator.wrap(User.recent)}
    )
  end

  def broadcast_latest_import
    import = Import.latest.first

    if import
      Turbo::StreamsChannel.broadcast_replace_to(
        DASHBOARD_STREAM,
        target: "latest_import",
        partial: "admin/dashboards/latest_import",
        locals: {import: Admin::ImportDecorator.new(import)}
      )
    else
      Turbo::StreamsChannel.broadcast_replace_to(
        DASHBOARD_STREAM, target: "latest_import", partial: "admin/dashboards/no_imports"
      )
    end
  end

  def broadcast_users_list(request_id = nil)
    refresh(USERS_STREAM, request_id)
  end

  def broadcast_imports_list(request_id = nil)
    refresh(IMPORTS_STREAM, request_id)
  end

  def broadcast_import(import_id, request_id = nil)
    refresh("import_#{import_id}", request_id)
  end

  def broadcast_sessions(user_id)
    user = User.find_by(id: user_id)
    return if user.blank?

    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user_id}_sessions",
      target: "sessions",
      partial: "profile/profiles/sessions_list",
      locals: {sessions: SessionDecorator.wrap(user.sessions)}
    )
  end
end

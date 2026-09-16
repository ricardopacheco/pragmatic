class ApplicationJob < ActiveJob::Base
  # Operations enqueue jobs inside transactions: hold the enqueue until the commit,
  # otherwise a worker can pick the job up before the records exist.
  self.enqueue_after_transaction_commit = true

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

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

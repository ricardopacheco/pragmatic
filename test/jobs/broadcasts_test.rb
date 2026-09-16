# frozen_string_literal: true

require "test_helper"

# The jobs share the broadcasting helpers of ApplicationJob, so they are covered
# together: what matters is which stream each event reaches.
class BroadcastsTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
  end

  test "signing in replaces the active sessions list of that user" do
    session = @admin.sessions.create!(ip_address: "203.0.113.7", user_agent: "Chrome")

    payload = capture_payloads("user_#{@admin.id}_sessions") do
      Sessions::CreateSessionBroadcastJob.perform_now(@admin.id)
    end

    assert_match(/id="sessions"/, payload.first)
    assert_match(/id="#{SessionDecorator.new(session).dom_id}"/, payload.first)
  end

  test "the sessions broadcast is skipped when the user is gone" do
    assert_empty capture_broadcasts { Sessions::DeleteSessionBroadcastJob.perform_now(0) }
  end

  test "nothing reaches the wire when the user of the sessions broadcast is gone" do
    ActionCable.server.expects(:broadcast).never

    Sessions::DeleteSessionBroadcastJob.perform_now(0)
  end

  private

  # Names of the streams that received a broadcast, in order.
  def capture_broadcasts
    broadcasts = []

    Turbo::StreamsChannel.stubs(:broadcast_stream_to).with { |*streams, **| broadcasts << streams.first.to_s }
    Turbo::StreamsChannel.stubs(:broadcast_refresh_to).with { |*streams, **| broadcasts << streams.first.to_s }

    yield

    broadcasts
  end

  def capture_payloads(stream)
    payloads = []

    # Refreshes are not stubbed here: they go through broadcast_stream_to, which is
    # where the rendered turbo-stream tag can be inspected.
    Turbo::StreamsChannel.stubs(:broadcast_stream_to).with do |*streams, **options|
      payloads << options[:content] if streams.first.to_s == stream
      true
    end

    yield

    payloads
  end
end

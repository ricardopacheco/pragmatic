# frozen_string_literal: true

require "test_helper"

# The jobs share the broadcasting helpers of ApplicationJob, so they are covered
# together: what matters is which stream each event reaches.
class BroadcastsTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
  end

  test "creating a user updates the dashboard and refreshes the users list" do
    streams = capture_broadcasts { Admin::CreateUserBroadcastJob.perform_now(create(:user).id) }

    assert_equal 2, streams.count("admin_dashboard")
    assert_includes streams, "admin_users"
  end

  test "the dashboard broadcast carries the current counters" do
    create_list(:user, 2)

    payload = capture_payloads("admin_dashboard") { Guest::RegisterUserBroadcastJob.perform_now(User.last.id) }

    assert_match(/id="dashboard_stats"/, payload.first)
    assert_match(/id="total_users_count"[^>]*>3</, payload.first.squish)
    assert_match(/id="recent_users"/, payload.last)
  end

  test "deleting a profile updates the dashboard and the users list" do
    streams = capture_broadcasts { Profile::DeleteProfileBroadcastJob.perform_now(@admin.id) }

    assert_includes streams, "admin_dashboard"
    assert_includes streams, "admin_users"
  end

  test "creating an import updates the dashboard card and the imports list" do
    import = create(:import, user: @admin)

    payload = capture_payloads("admin_dashboard") { Admin::CreateImportBroadcastJob.perform_now(import.id) }

    assert_match(/id="latest_import"/, payload.first)
    assert_match(/users\.csv/, payload.first)
  end

  test "the dashboard card falls back to the empty state without imports" do
    payload = capture_payloads("admin_dashboard") { Admin::CreateImportBroadcastJob.perform_now(nil) }

    assert_match(/#{I18n.t("admin.dashboards.no_imports.heading")}/, payload.first)
  end

  test "import progress reaches the import page, the list and the dashboard" do
    import = create(:import, user: @admin, status: :processing, total_rows: 10, succeeded_rows: 5)

    streams = capture_broadcasts { Admin::ImportProgressBroadcastJob.perform_now(import.id) }

    assert_includes streams, "import_#{import.id}"
    assert_includes streams, "admin_imports"
    assert_includes streams, "admin_dashboard"
  end

  test "the refresh carries the request id, so the acting tab keeps its flash message" do
    payload = capture_payloads("admin_users") do
      Admin::DeleteUserBroadcastJob.perform_now(@admin.id, request_id: "d3adb33f")
    end

    assert_match(/request-id="d3adb33f"/, payload.first)
  end

  test "the refresh has no request id when nobody asked for it" do
    import = create(:import, user: @admin)

    payload = capture_payloads("admin_imports") { Admin::ImportProgressBroadcastJob.perform_now(import.id) }

    assert_no_match(/request-id/, payload.first)
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

  # The jobs below only re-render from the database, so what there is to assert about
  # #perform is how many messages reach the wire. Counting at ActionCable.server, the
  # single funnel every Turbo broadcast goes through, also means nothing above it is
  # stubbed: the partials really render.
  test "updating a user pushes the two dashboard blocks and the list refresh" do
    ActionCable.server.expects(:broadcast).times(3)

    Admin::UpdateUserBroadcastJob.perform_now(@admin.id)
  end

  test "changing a role pushes the two dashboard blocks and the list refresh" do
    ActionCable.server.expects(:broadcast).times(3)

    Admin::UpdateUserRoleBroadcastJob.perform_now(@admin.id)
  end

  test "updating a profile pushes the two dashboard blocks and the list refresh" do
    ActionCable.server.expects(:broadcast).times(3)

    Profile::UpdateProfileBroadcastJob.perform_now(@admin.id)
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

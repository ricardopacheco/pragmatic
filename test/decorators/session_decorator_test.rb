# frozen_string_literal: true

require "test_helper"

class SessionDecoratorTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @session = @user.sessions.create!(ip_address: "203.0.113.7", user_agent: "Mozilla/5.0 Chrome/140")
  end

  test "exposes the declared attributes" do
    decorator = SessionDecorator.new(@session)

    assert_equal({id: @session.id, ip_address: "203.0.113.7"}, decorator.to_h)
  end

  test "reduces the user agent to browser and platform" do
    assert_equal "Chrome", SessionDecorator.new(@session).browser
  end

  test "recognizes browser and operating system together" do
    session = @user.sessions.create!(
      ip_address: "203.0.113.9",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140 Safari/537.36"
    )

    assert_equal "Chrome · macOS", SessionDecorator.new(session).browser
  end

  test "falls back to a truncated user agent when nothing is recognized" do
    session = @user.sessions.create!(ip_address: "203.0.113.10", user_agent: "curl/8.22.0")

    assert_equal "curl/8.22.0", SessionDecorator.new(session).browser
  end

  test "falls back when the browser is unknown" do
    session = @user.sessions.create!(ip_address: "203.0.113.8", user_agent: nil)

    assert_equal I18n.t("decorators.session.unknown_browser"), SessionDecorator.new(session).browser
  end

  test "knows which session is the current one" do
    assert_predicate SessionDecorator.new(@session, @session.id), :current?
    assert_not_predicate SessionDecorator.new(@session, 0), :current?
    assert_not_predicate SessionDecorator.new(@session), :current?
  end

  test "formats when the session started" do
    assert_equal I18n.l(@session.created_at, format: :short), SessionDecorator.new(@session).started_at
  end

  test "builds the dom id used by the turbo streams" do
    assert_equal "session_#{@session.id}", SessionDecorator.new(@session).dom_id
  end

  test "wraps a collection keeping the current session" do
    decorators = SessionDecorator.wrap(@user.sessions, @session.id)

    assert_equal [true], decorators.map(&:current?)
  end
end

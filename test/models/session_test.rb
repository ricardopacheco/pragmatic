# frozen_string_literal: true

require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "requires a user" do
    session = Session.new

    assert_not session.valid?
    assert_includes session.errors.details[:user].pluck(:error), :blank
  end

  test "stores the ip address and the user agent encrypted" do
    session = create(:user).sessions.create!(ip_address: "203.0.113.7", user_agent: "Chrome")

    assert session.encrypted_attribute?(:ip_address)
    assert session.encrypted_attribute?(:user_agent)
    assert_not_equal "203.0.113.7", session.ciphertext_for(:ip_address)
  end
end

# frozen_string_literal: true

module Profile
  class ProfilesController < BaseController
    def show
      user = Current.user

      @user = UserDecorator.new(user)
      @sessions = SessionDecorator.wrap(user.sessions, Current.session.id)
    end
  end
end

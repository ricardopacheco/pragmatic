# frozen_string_literal: true

module Profile
  class ProfilesController < ApplicationController
    def show
      @user = Current.user
    end
  end
end

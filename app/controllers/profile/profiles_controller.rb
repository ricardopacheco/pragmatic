# frozen_string_literal: true

module Profile
  class ProfilesController < BaseController
    def show
      user = Current.user

      @user = UserDecorator.new(user)
      @sessions = SessionDecorator.wrap(user.sessions, Current.session.id)
    end

    def edit
      @form = UpdateProfileForm.new(user: Current.user)
      @password_form = UpdatePasswordForm.new
    end

    def update
      @form = UpdateProfileForm.new(profile_params.merge(user: Current.user))

      if @form.submit(Current.user.id)
        redirect_to profile_path, notice: t(".success")
      else
        @password_form = UpdatePasswordForm.new
        render :edit, status: :unprocessable_content
      end
    end

    private

    def profile_params
      params.expect(user: %i[full_name email avatar_image remove_avatar_image])
    end
  end
end

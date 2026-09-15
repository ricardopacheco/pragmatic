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

    def destroy
      DeleteProfileOperation.call(Current.user.id) do |result|
        result.success do
          cookies.delete(:session_id)

          redirect_to root_path, notice: t(".success")
        end

        result.failure do |errors|
          redirect_to profile_path, alert: Array(errors.values).flatten.to_sentence
        end
      end
    end

    private

    def profile_params
      params.expect(user: %i[full_name email avatar_image remove_avatar_image])
    end
  end
end

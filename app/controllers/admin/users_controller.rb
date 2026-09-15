# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    PER_PAGE = 8

    def index
      @page = [params[:page].to_i, 1].max
      @total = filtered_users.count
      @users = UserDecorator.wrap(filtered_users.order(created_at: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE))
      @presenter = presenter_class.new(view_context, Current.user, users: @users)
    end

    def new
      @form = CreateUserForm.new
    end

    def create
      @form = CreateUserForm.new(user_params)

      if @form.submit(Current.user.id)
        redirect_to admin_users_path, notice: t(".success")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @form = UpdateUserForm.new(user: user)
    end

    def update
      @form = UpdateUserForm.new(user_params.merge(user:))

      if @form.submit(Current.user.id, user.id)
        redirect_to admin_users_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      DeleteUserOperation.call(Current.user.id, params[:id]) do |result|
        result.success { redirect_to admin_users_path, notice: t(".success") }
        result.failure { |errors| redirect_to admin_users_path, alert: Array(errors.values).flatten.to_sentence }
      end
    end

    private

    def user
      @user ||= User.find(params[:id])
    end

    def filtered_users
      role = params[:role]
      scope = User.all
      scope = scope.where(role:) if User.roles.key?(role)
      scope = scope.where(search_condition) if params[:query].present?
      scope
    end

    def search_condition
      term = "%#{params[:query].strip}%"
      users = User.arel_table

      users[:full_name].matches(term).or(users[:email].matches(term))
    end

    def user_params
      params.expect(
        user: %i[full_name email role password password_confirmation avatar_image remove_avatar_image]
      )
    end
  end
end

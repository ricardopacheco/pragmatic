# frozen_string_literal: true

require "test_helper"

module Admin
  class DashboardsPresenterTest < ActiveSupport::TestCase
    setup do
      @view_context = mock("view_context")
      @admin = build(:user, :admin)
    end

    test "renders the empty card when there is no import yet" do
      @view_context.expects(:render).with({partial: "admin/dashboards/no_imports"}).returns("no imports")

      presenter = DashboardsPresenter.new(@view_context, @admin, latest_import: nil)

      assert_equal "no imports", presenter.render_latest_import
    end

    test "renders the empty card when no import is given" do
      @view_context.expects(:render).with({partial: "admin/dashboards/no_imports"}).returns("no imports")

      presenter = DashboardsPresenter.new(@view_context, @admin)

      assert_equal "no imports", presenter.render_latest_import
    end

    test "renders the latest import card with the decorated import" do
      import = Admin::ImportDecorator.new(create(:import))
      @view_context
        .expects(:render)
        .with({partial: "admin/dashboards/latest_import", locals: {import:}})
        .returns("latest import")

      presenter = DashboardsPresenter.new(@view_context, @admin, latest_import: import)

      assert_equal "latest import", presenter.render_latest_import
    end
  end
end

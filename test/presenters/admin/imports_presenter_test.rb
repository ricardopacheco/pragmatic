# frozen_string_literal: true

require "test_helper"

module Admin
  class ImportsPresenterTest < ActiveSupport::TestCase
    setup do
      @view_context = mock("view_context")
      @import = create(:import)
    end

    test "renders the empty state when there are no imports" do
      @view_context.expects(:render).with({partial: "admin/imports/empty"}).returns("empty")

      presenter = ImportsPresenter.new(@view_context, imports: [])

      assert_equal "empty", presenter.render_imports
    end

    test "renders the table with the decorated imports" do
      imports = Admin::ImportDecorator.wrap([@import])
      @view_context.expects(:render).with({partial: "admin/imports/table", locals: {imports:}}).returns("table")

      presenter = ImportsPresenter.new(@view_context, imports:)

      assert_equal "table", presenter.render_imports
    end

    test "renders the progress card while the import is running" do
      import = decorated(@import)
      @view_context.expects(:render).with({partial: "admin/imports/progress", locals: {import:}}).returns("progress")

      assert_equal "progress", presenter(import:).render_status_card
    end

    test "renders the completed card when the import finished without errors" do
      @import.update!(status: :completed)
      import = decorated(@import)
      @view_context.expects(:render).with({partial: "admin/imports/completed", locals: {import:}}).returns("completed")

      assert_equal "completed", presenter(import:).render_status_card
    end

    test "renders the failure card when the import failed" do
      @import.update!(status: :failed, failure_reason: "Unsupported file format")
      import = decorated(@import)
      @view_context.expects(:render).with({partial: "admin/imports/failure", locals: {import:}}).returns("failure")

      assert_equal "failure", presenter(import:).render_status_card
    end

    test "renders the progress card when the import finished with errors" do
      @import.update!(status: :completed_with_errors)
      import = decorated(@import)
      @view_context.expects(:render).with({partial: "admin/imports/progress", locals: {import:}}).returns("progress")

      assert_equal "progress", presenter(import:).render_status_card
    end

    test "does not render the failures when there are none" do
      @view_context.expects(:render).never

      assert_nil presenter(import: decorated(@import)).render_failures
    end

    test "renders the failures when the import has failed rows" do
      @import.update!(failed_rows: 1, row_errors: [{"row" => 4, "data" => {}, "messages" => ["Email is invalid"]}])
      import = decorated(@import)
      @view_context.expects(:render).with({partial: "admin/imports/failures", locals: {import:}}).returns("failures")

      assert_equal "failures", presenter(import:).render_failures
    end

    private

    def decorated(import)
      Admin::ImportDecorator.new(import)
    end

    def presenter(options)
      ImportsPresenter.new(@view_context, options)
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Admin
  class ImportDecoratorTest < ActiveSupport::TestCase
    setup do
      @import = create(:import)
      @decorator = ImportDecorator.new(@import)
    end

    test "exposes the file name" do
      assert_equal "users.csv", @decorator.filename
    end

    test "translates the status and gives its badge class" do
      assert_equal I18n.t("decorators.import.statuses.queued"), @decorator.status_label
      assert_equal "badge-ghost", @decorator.status_badge_class
    end

    test "translates the status in the current locale" do
      I18n.with_locale(:pt) do
        assert_equal "Na fila", @decorator.status_label
      end
    end

    test "gives the badge class of every status" do
      {
        "processing" => "badge-soft badge-info",
        "completed" => "badge-soft badge-success",
        "completed_with_errors" => "badge-soft badge-warning",
        "failed" => "badge-soft badge-error"
      }.each do |status, badge_class|
        @import.status = status

        assert_equal badge_class, ImportDecorator.new(@import).status_badge_class
      end
    end

    test "has no progress when there are no rows yet" do
      assert_equal 0, @decorator.progress_percentage
      assert_equal 0, @decorator.processed_rows
      assert_equal 0, @decorator.pending_rows
      assert_not_predicate @decorator, :failures?
    end

    test "calculates progress, processed and pending rows" do
      @import.update!(total_rows: 1280, succeeded_rows: 812, failed_rows: 8)

      assert_equal 820, @decorator.processed_rows
      assert_equal 460, @decorator.pending_rows
      assert_equal 64, @decorator.progress_percentage
    end

    test "never goes below zero pending rows" do
      @import.update!(total_rows: 2, succeeded_rows: 3, failed_rows: 0)

      assert_equal 0, @decorator.pending_rows
    end

    test "exposes the failed rows" do
      @import.update!(failed_rows: 1, row_errors: [{"row" => 4, "data" => {}, "messages" => ["Email is invalid"]}])

      assert_predicate @decorator, :failures?
      assert_equal 4, @decorator.failures.sole["row"]
    end

    test "formats the timestamps only when they exist" do
      assert_nil @decorator.started_at
      assert_nil @decorator.finished_at

      @import.update!(started_at: Time.current, finished_at: Time.current)

      assert_equal I18n.l(@import.started_at, format: :short), @decorator.started_at
      assert_equal I18n.l(@import.finished_at, format: :short), @decorator.finished_at
    end

    test "builds the dom id used by the turbo streams" do
      assert_equal "import_#{@import.id}", @decorator.dom_id
    end
  end
end

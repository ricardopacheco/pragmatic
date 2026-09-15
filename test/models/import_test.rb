# frozen_string_literal: true

require "test_helper"

class ImportTest < ActiveSupport::TestCase
  COUNTERS = %i[total_rows succeeded_rows failed_rows].freeze

  test "the factory builds a valid import" do
    assert_predicate build(:import), :valid?
  end

  test "requires a user" do
    import = build(:import, user: nil)

    assert_not import.valid?
    assert_includes import.errors.details[:user].pluck(:error), :blank
  end

  test "is queued by default" do
    assert_predicate Import.new, :queued?
  end

  test "defines the statuses" do
    assert_equal %w[queued processing completed completed_with_errors failed], Import.statuses.keys
  end

  test "rejects an unknown status without raising" do
    import = build(:import, status: "archived")

    assert_not import.valid?
    assert_includes import.errors.details[:status].pluck(:error), :inclusion
  end

  test "requires the counters to be non-negative integers" do
    COUNTERS.each do |counter|
      assert_not build(:import, counter => -1).valid?, "#{counter} should reject negatives"
      assert_not build(:import, counter => 1.5).valid?, "#{counter} should reject decimals"
      assert_predicate build(:import, counter => 0), :valid?
    end
  end

  test "requires a spreadsheet" do
    import = build(:import, spreadsheet: nil)

    assert_not import.valid?
    assert_predicate import.errors[:spreadsheet], :any?
  end

  test "rejects a spreadsheet that is not csv or xlsx" do
    import = build(:import, spreadsheet: fixture_file_upload("avatar.png", "image/png"))

    assert_not import.valid?
    assert_predicate import.errors[:spreadsheet], :any?
  end

  test "rejects a spreadsheet larger than 10 MB" do
    csv = file_fixture("users.csv").read
    padding = "\n" + ("a" * (10.megabytes + 1 - csv.bytesize))
    import = build(:import, spreadsheet: nil)
    import.spreadsheet.attach(io: StringIO.new(csv + padding), filename: "big.csv", content_type: "text/csv")

    assert_not import.valid?
    assert_predicate import.errors[:spreadsheet], :any?
  end

  test "latest lists the imports from the newest to the oldest" do
    older = create(:import, created_at: 2.days.ago)
    newer = create(:import, created_at: 1.hour.ago)

    assert_equal [newer, older], Import.latest.to_a
  end
end

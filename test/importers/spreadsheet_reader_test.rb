# frozen_string_literal: true

require "test_helper"

class SpreadsheetReaderTest < ActiveSupport::TestCase
  test "for returns nil for an unsupported content type" do
    assert_nil SpreadsheetReader.for("image/png")
  end

  test "for returns the reader of each supported format" do
    assert_equal SpreadsheetReader::Csv, SpreadsheetReader.for("text/csv")
    assert_equal SpreadsheetReader::Xlsx,
      SpreadsheetReader.for("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  test "base reader requires the format to implement the hooks" do
    reader = SpreadsheetReader::Base.new(file_fixture("users.csv").to_s)

    assert_raises(NotImplementedError) { reader.each_row { |_row_number, _attributes| } }
    assert_raises(NotImplementedError) { reader.total_rows }
  end

  # The headers are read before the rows, so a format that implements only the first
  # hook is what gets far enough to reach the second one.
  test "base reader still requires each_raw_row once the headers are implemented" do
    reader_class = Class.new(SpreadsheetReader::Base) do
      private

      def read_headers = SpreadsheetReader::Base::REQUIRED_HEADERS
    end

    reader = reader_class.new(file_fixture("users.csv").to_s)

    assert_raises(NotImplementedError) { reader.each_row { |_row_number, _attributes| } }
  end

  class CsvTest < ActiveSupport::TestCase
    setup do
      @reader = SpreadsheetReader::Csv.new(file_fixture("users.csv").to_s)
    end

    test "fails when required headers are missing" do
      reader = SpreadsheetReader::Csv.new(file_fixture("users_missing_headers.csv").to_s)

      error = assert_raises(SpreadsheetReader::MissingHeadersError) { reader.each_row { |_, _| } }
      assert_equal "full_name, email", error.message
    end

    test "counts only the data rows" do
      assert_equal 3, @reader.total_rows
    end

    test "yields the row number and the attributes of each row" do
      rows = @reader.each_row.to_a

      assert_equal 3, rows.size
      assert_equal [2, {full_name: "João Silva", email: "joao@example.com", role: "profile"}], rows.first
      assert_equal 4, rows.last.first
    end
  end

  class XlsxTest < ActiveSupport::TestCase
    setup do
      @reader = SpreadsheetReader::Xlsx.new(file_fixture("users.xlsx").to_s)
    end

    test "counts only the data rows" do
      assert_equal 2, @reader.total_rows
    end

    test "yields the row number and the attributes of each row" do
      rows = @reader.each_row.to_a

      assert_equal 2, rows.size
      assert_equal [2, {full_name: "João Silva", email: "joao@example.com", role: "profile"}], rows.first
      assert_equal [3, {full_name: "Maria Souza", email: "maria@example.com", role: "admin"}], rows.last
    end
  end
end

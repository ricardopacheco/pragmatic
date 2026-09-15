# frozen_string_literal: true

module SpreadsheetReader
  class Xlsx < Base
    def total_rows
      [spreadsheet.last_row.to_i - 1, 0].max
    end

    private

    def spreadsheet
      @spreadsheet ||= Roo::Spreadsheet.open(path, extension: :xlsx)
    end

    def read_headers
      values_of(spreadsheet.each_row_streaming(pad_cells: true).first)
    end

    def each_raw_row
      return to_enum(:each_raw_row) unless block_given?

      spreadsheet.each_row_streaming(pad_cells: true).with_index do |row, index|
        next if index.zero?

        yield values_of(row)
      end
    end

    def values_of(row)
      Array(row).map { |cell| cell&.value }
    end
  end
end

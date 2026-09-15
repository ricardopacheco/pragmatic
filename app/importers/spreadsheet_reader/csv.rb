# frozen_string_literal: true

module SpreadsheetReader
  class Csv < Base
    def total_rows
      count = 0

      ::CSV.foreach(path).with_index { |row, index| count += 1 if index.positive? && row.any?(&:present?) }

      count
    end

    private

    def read_headers
      ::CSV.foreach(path).first
    end

    def each_raw_row
      return to_enum(:each_raw_row) unless block_given?

      ::CSV.foreach(path).with_index do |row, index|
        next if index.zero?

        yield row
      end
    end
  end
end

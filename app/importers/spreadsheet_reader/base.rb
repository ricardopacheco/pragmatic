# frozen_string_literal: true

module SpreadsheetReader
  # Template method: the algorithm lives here and each format only implements how to
  # read the raw rows of its own file.
  class Base
    KNOWN_HEADERS = %w[full_name email role].freeze
    REQUIRED_HEADERS = %w[full_name email].freeze

    def initialize(path)
      @path = path
    end

    def each_row
      return to_enum(:each_row) unless block_given?

      headers = validated_headers

      each_raw_row.with_index(2) do |cells, row_number|
        next if cells.all?(&:blank?)

        yield row_number, attributes_for(headers, cells)
      end
    end

    # Number of data rows, used for the progress bar.
    def total_rows
      raise NotImplementedError
    end

    private

    attr_reader :path

    # Hooks implemented by each format.
    def read_headers
      raise NotImplementedError
    end

    def each_raw_row
      raise NotImplementedError
    end

    def validated_headers
      headers = Array(read_headers).map { |header| header.to_s.strip.downcase }
      missing = REQUIRED_HEADERS - headers

      raise MissingHeadersError, missing.join(", ") if missing.any?

      headers
    end

    def attributes_for(headers, cells)
      headers.zip(cells).to_h
        .slice(*KNOWN_HEADERS)
        .to_h { |header, cell| [header.to_sym, cell.to_s.strip] }
    end
  end
end

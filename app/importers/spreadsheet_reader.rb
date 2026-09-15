# frozen_string_literal: true

module SpreadsheetReader
  Error = Class.new(StandardError)
  MissingHeadersError = Class.new(Error)

  READERS = {
    "text/csv" => "SpreadsheetReader::Csv",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => "SpreadsheetReader::Xlsx"
  }.freeze

  def self.for(content_type)
    READERS[content_type]&.constantize
  end
end

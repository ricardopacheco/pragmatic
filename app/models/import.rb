# frozen_string_literal: true

class Import < ApplicationRecord
  belongs_to :user

  has_one_attached :spreadsheet

  enum :status, {queued: 0, processing: 1, completed: 2, completed_with_errors: 3, failed: 4}, validate: true

  scope :latest, -> { order(created_at: :desc) }

  validates :total_rows, :succeeded_rows, :failed_rows, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :spreadsheet, attached: true, content_type: {with: %i[csv xlsx], spoofing_protection: true}, size: {less_than_or_equal_to: 10.megabytes}

  def processed_rows = succeeded_rows + failed_rows

  def finish!
    update!(status: failed_rows.zero? ? :completed : :completed_with_errors, finished_at: Time.current)
  end
end

# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :sessions, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :imports, dependent: :destroy

  has_one_attached :avatar_image do |attachable|
    attachable.variant :thumb, resize_to_fill: [72, 72, {crop: :attention}], format: :webp, preprocessed: true
    attachable.variant :medium, resize_to_fill: [112, 112, {crop: :attention}], format: :webp, preprocessed: true
    attachable.variant :large, resize_to_fill: [192, 192, {crop: :attention}], format: :webp, preprocessed: true
  end

  enum :role, {profile: 0, admin: 1}, validate: true

  RECENT_LIMIT = 4

  scope :recent, -> { order(created_at: :desc).limit(RECENT_LIMIT) }
  scope :with_role, ->(role) { where(role:) if roles.key?(role) }
  scope :search, ->(query) do
    next if query.blank?

    term = "%#{query.strip}%"
    where(arel_table[:full_name].matches(term).or(arel_table[:email].matches(term)))
  end

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :full_name, presence: true, length: {in: Rails.configuration.x.validations.full_name_length}
  validates :email, presence: true, format: {with: Rails.configuration.x.validations.email_format}, uniqueness: true
  validates :password, length: {in: Rails.configuration.x.validations.password_length}, allow_nil: true
  validates :avatar_image, content_type: {with: %i[png jpg webp], spoofing_protection: true}, size: {less_than_or_equal_to: 5.megabytes}
end

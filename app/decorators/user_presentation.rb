# frozen_string_literal: true

# Shared presentation of a user, used by the admin and profile decorators.
module UserPresentation
  def initials
    parts = item.full_name.to_s.split

    [parts.first, (parts.last if parts.size > 1)].compact.map(&:chr).join.upcase
  end

  def avatar?
    item.avatar_image.attached?
  end

  def avatar_variant(size = :thumb)
    return unless avatar?

    item.avatar_image.variant(size)
  end

  def role_label
    t("decorators.user.roles.#{item.role}")
  end

  def dom_id
    "user_#{item.id}"
  end
end

class User < ApplicationRecord
  validates :spotify_id, presence: true, uniqueness: true

  def token_expired?
    token_expires_at.present? && token_expires_at <= Time.current
  end
end

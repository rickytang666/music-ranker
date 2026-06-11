class Song < ApplicationRecord
  JSON_FIELDS = %i[id spotify_track_id title artist_name album_name album_art_url].freeze
  has_many :ranking_songs, dependent: :destroy
  has_many :rankings, through: :ranking_songs

  validates :spotify_track_id, presence: true, uniqueness: true
  validates :title, :artist_name, presence: true
end

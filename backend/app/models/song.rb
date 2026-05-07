class Song < ApplicationRecord
  has_many :ranking_songs, dependent: :destroy
  has_many :rankings, through: :ranking_songs

  validates :spotify_track_id, presence: true, uniqueness: true
  validates :title, :artist_name, presence: true
end

class Ranking < ApplicationRecord
  belongs_to :user
  has_many :ranking_songs, dependent: :destroy
  has_many :songs, through: :ranking_songs
  has_many :matchups, dependent: :destroy

  validates :name, presence: true
end

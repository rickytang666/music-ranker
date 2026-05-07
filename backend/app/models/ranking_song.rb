class RankingSong < ApplicationRecord
  belongs_to :ranking
  belongs_to :song

  validates :elo_score, presence: true
  validates :song_id, uniqueness: { scope: :ranking_id }

  before_destroy :purge_matchups

  private

  def purge_matchups
    ranking.matchups.where("song_a_id = ? OR song_b_id = ?", song_id, song_id).delete_all
  end
end

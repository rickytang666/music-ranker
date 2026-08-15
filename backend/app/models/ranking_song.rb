class RankingSong < ApplicationRecord
  DEFAULT_ELO = 1000.0

  belongs_to :ranking
  belongs_to :song

  # tie-break by release date (as yyyymmdd int, missing dates sort last)
  scope :ranked_order, -> {
    includes(:song).sort_by { |rs| [-rs.elo_score, -(rs.song.release_date || "0").tr("-", "").to_i] }
  }

  validates :elo_score, presence: true
  validates :song_id, uniqueness: { scope: :ranking_id }

  before_destroy :purge_matchups

  private

  def purge_matchups
    ranking.matchups.where("song_a_id = ? OR song_b_id = ?", song_id, song_id).delete_all
  end
end

class Matchup < ApplicationRecord
  QUEUE_CAP = 50

  belongs_to :ranking
  belongs_to :song_a, class_name: "Song"
  belongs_to :song_b, class_name: "Song"
  belongs_to :winner, class_name: "Song"

  validates :played_at, presence: true

  after_create :purge_overflow

  private

  def purge_overflow
    overflow = ranking.matchups.order(played_at: :asc)
                      .offset(QUEUE_CAP)
                      .ids
    Matchup.where(id: overflow).delete_all if overflow.any?
  end
end

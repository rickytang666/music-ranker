class EloService
  BASE_K = 32
  PROVISIONAL_K = 64
  PROVISIONAL_THRESHOLD = 10

  def self.call(winner_rs, loser_rs)
    new(winner_rs, loser_rs).call
  end

  def initialize(winner_rs, loser_rs)
    @winner_rs = winner_rs
    @loser_rs  = loser_rs
  end

  def call
    e_winner = expected(@winner_rs.elo_score, @loser_rs.elo_score)
    e_loser  = 1.0 - e_winner

    @winner_rs.update!(
      elo_score:     @winner_rs.elo_score + k(@winner_rs) * (1.0 - e_winner),
      matchup_count: @winner_rs.matchup_count + 1
    )
    @loser_rs.update!(
      elo_score:     @loser_rs.elo_score + k(@loser_rs) * (0.0 - e_loser),
      matchup_count: @loser_rs.matchup_count + 1
    )
  end

  private

  def expected(rating_a, rating_b)
    1.0 / (1.0 + 10.0**((rating_b - rating_a) / 400.0))
  end

  def k(ranking_song)
    ranking_song.matchup_count < PROVISIONAL_THRESHOLD ? PROVISIONAL_K : BASE_K
  end
end

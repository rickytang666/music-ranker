class EloService
  BASE_K = 32
  PROVISIONAL_K = 64
  PROVISIONAL_THRESHOLD = 10

  def self.call(winner_rs, loser_rs, confidence: 1.0)
    new(winner_rs, loser_rs, confidence: confidence).call
  end

  def initialize(winner_rs, loser_rs, confidence: 1.0)
    @winner_rs = winner_rs
    @loser_rs  = loser_rs
    @confidence = confidence
  end

  def call
    e_winner = expected(@winner_rs.elo_score, @loser_rs.elo_score)
    e_loser  = 1.0 - e_winner
    adjusted_k_winner = adjusted_k(@winner_rs)
    adjusted_k_loser = adjusted_k(@loser_rs)

    @winner_rs.update!(
      elo_score:     @winner_rs.elo_score + adjusted_k_winner * (1.0 - e_winner),
      matchup_count: @winner_rs.matchup_count + 1
    )
    @loser_rs.update!(
      elo_score:     @loser_rs.elo_score - adjusted_k_loser * e_loser,
      matchup_count: @loser_rs.matchup_count + 1
    )
  end

  private

  def expected(rating_a, rating_b)
    1.0 / (1.0 + 10.0**((rating_b - rating_a) / 400.0))
  end

  def base_k(ranking_song)
    ranking_song.matchup_count < PROVISIONAL_THRESHOLD ? PROVISIONAL_K : BASE_K
  end

  def adjusted_k(ranking_song)
    base = base_k(ranking_song)
    base * (@confidence - 0.5).abs * 2
  end
end

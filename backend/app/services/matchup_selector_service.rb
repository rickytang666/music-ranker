class MatchupSelectorService
  def self.call(ranking, excluded_pairs: [])
    new(ranking, excluded_pairs).call
  end

  def initialize(ranking, excluded_pairs = [])
    @ranking        = ranking
    @excluded_pairs = excluded_pairs.map { |p| p.map(&:to_i).sort }
  end

  def call
    ranking_songs = @ranking.ranking_songs.includes(:song).to_a
    return nil if ranking_songs.size < 2

    counts    = pair_counts
    song_a_rs = weighted_sample(ranking_songs)

    candidates = ranking_songs.reject { |rs|
      rs == song_a_rs || excluded_pair?(song_a_rs.song_id, rs.song_id)
    }

    # fallback: relax excluded_pairs
    candidates = ranking_songs.reject { |rs| rs == song_a_rs } if candidates.empty?
    return nil if candidates.empty?

    song_b_rs = weighted_sample_opponent(candidates, song_a_rs, counts)
    { song_a: song_a_rs.song, song_b: song_b_rs.song }
  end

  private

  def weighted_sample(ranking_songs)
    sample_by_weights(ranking_songs) { |rs| 1.0 / (rs.matchup_count + 1) }
  end

  def weighted_sample_opponent(candidates, song_a_rs, counts)
    sample_by_weights(candidates) do |rs|
      pair_key    = [ song_a_rs.song_id, rs.song_id ].sort
      pair_w      = 1.0 / (counts[pair_key] + 1)
      elo_diff    = (rs.elo_score - song_a_rs.elo_score).abs
      proximity_w = Math.exp(-elo_diff / 200.0)
      pair_w * proximity_w
    end
  end

  def sample_by_weights(items, &weight_fn)
    weights    = items.map(&weight_fn)
    total      = weights.sum
    r          = rand * total
    cumulative = 0.0
    items.each_with_index do |item, i|
      cumulative += weights[i]
      return item if cumulative >= r
    end
    items.last
  end

  def excluded_pair?(id_a, id_b)
    @excluded_pairs.include?([ id_a, id_b ].sort)
  end

  def pair_counts
    @ranking.matchups.pluck(:song_a_id, :song_b_id)
            .each_with_object(Hash.new(0)) { |(a, b), h| h[[ a, b ].sort] += 1 }
  end
end

class MatchupSelectorService
  FLAG_BOOST = 3.0

  def self.call(ranking, signals = {})
    new(ranking, signals).call
  end

  def initialize(ranking, signals)
    @ranking       = ranking
    @overrated_ids = (signals[:overrated_ids] || []).map(&:to_i)
    @underrated_ids = (signals[:underrated_ids] || []).map(&:to_i)
    @unsure_ids    = (signals[:unsure_ids] || []).map(&:to_i)
    @all_flagged   = @overrated_ids + @underrated_ids + @unsure_ids
  end

  def call
    ranking_songs = @ranking.ranking_songs.includes(:song).to_a
    return nil if ranking_songs.size < 2

    recent_pairs = recent_played_pairs

    song_a_rs = weighted_sample(ranking_songs)
    candidates = valid_opponents(song_a_rs, ranking_songs, recent_pairs)

    # fallback: relax recency filter if no candidates
    if candidates.empty?
      candidates = ranking_songs.reject { |rs| rs == song_a_rs }
    end

    return nil if candidates.empty?

    song_b_rs = candidates.sample

    { song_a: song_a_rs.song, song_b: song_b_rs.song }
  end

  private

  def weighted_sample(ranking_songs)
    weights = ranking_songs.map { |rs| weight(rs) }
    total   = weights.sum
    r       = rand * total
    cumulative = 0.0
    ranking_songs.each_with_index do |rs, i|
      cumulative += weights[i]
      return rs if cumulative >= r
    end
    ranking_songs.last
  end

  def weight(rs)
    base = 1.0 / (rs.matchup_count + 1)
    @all_flagged.include?(rs.song_id) ? base * FLAG_BOOST : base
  end

  def valid_opponents(song_a_rs, all_rs, recent_pairs)
    all_rs.reject do |rs|
      rs == song_a_rs ||
        recently_played?(song_a_rs.song_id, rs.song_id, recent_pairs) ||
        violates_constraint?(song_a_rs, rs)
    end
  end

  def violates_constraint?(song_a_rs, opponent_rs)
    id = song_a_rs.song_id
    if @overrated_ids.include?(id)
      opponent_rs.elo_score >= song_a_rs.elo_score
    elsif @underrated_ids.include?(id)
      opponent_rs.elo_score <= song_a_rs.elo_score
    else
      false
    end
  end

  def recently_played?(id_a, id_b, recent_pairs)
    recent_pairs.include?([ id_a, id_b ].sort)
  end

  def recent_played_pairs
    @ranking.matchups.pluck(:song_a_id, :song_b_id)
            .map { |a, b| [ a, b ].sort }
            .to_set
  end
end

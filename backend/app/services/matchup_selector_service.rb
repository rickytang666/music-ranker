class MatchupSelectorService
  def self.call(ranking, signals = {}, excluded_pairs: [])
    new(ranking, signals, excluded_pairs).call
  end

  def initialize(ranking, signals, excluded_pairs = [])
    @ranking        = ranking
    @overrated_ids  = (signals[:overrated_ids]  || []).map(&:to_i)
    @underrated_ids = (signals[:underrated_ids] || []).map(&:to_i)
    @unsure_ids     = (signals[:unsure_ids]     || []).map(&:to_i)
    @all_flagged    = @overrated_ids + @underrated_ids + @unsure_ids
    @excluded_pairs = excluded_pairs.map { |p| p.map(&:to_i).sort }
  end

  def call
    ranking_songs = @ranking.ranking_songs.includes(:song).to_a
    return nil if ranking_songs.size < 2

    recent_pairs = recent_played_pairs

    # flagged songs are forced into every matchup
    flagged = ranking_songs.select { |rs| @all_flagged.include?(rs.song_id) }
    song_a_rs = flagged.any? ? flagged.sample : weighted_sample(ranking_songs)

    # try candidates with all constraints
    candidates = valid_opponents(song_a_rs, ranking_songs, recent_pairs)

    # fallback 1: relax recency
    if candidates.empty?
      candidates = ranking_songs.reject { |rs| rs == song_a_rs || violates_constraint?(song_a_rs, rs) || excluded_pair?(song_a_rs.song_id, rs.song_id) }
    end

    # fallback 2: relax everything
    if candidates.empty?
      candidates = ranking_songs.reject { |rs| rs == song_a_rs }
    end

    return nil if candidates.empty?

    song_b_rs = weighted_sample_opponent(candidates, song_a_rs)
    { song_a: song_a_rs.song, song_b: song_b_rs.song }
  end

  private

  def weighted_sample(ranking_songs)
    sample_by_weights(ranking_songs) { |rs| 1.0 / (rs.matchup_count + 1) }
  end

  # combines low-matchup preference with ELO proximity
  def weighted_sample_opponent(candidates, song_a_rs)
    sample_by_weights(candidates) do |rs|
      matchup_w  = 1.0 / (rs.matchup_count + 1)
      elo_diff   = (rs.elo_score - song_a_rs.elo_score).abs
      proximity_w = Math.exp(-elo_diff / 400.0)
      matchup_w * proximity_w
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

  def valid_opponents(song_a_rs, all_rs, recent_pairs)
    all_rs.reject do |rs|
      rs == song_a_rs ||
        recently_played?(song_a_rs.song_id, rs.song_id, recent_pairs) ||
        violates_constraint?(song_a_rs, rs) ||
        excluded_pair?(song_a_rs.song_id, rs.song_id)
    end
  end

  def excluded_pair?(id_a, id_b)
    @excluded_pairs.include?([ id_a, id_b ].sort)
  end

  def violates_constraint?(song_a_rs, opponent_rs)
    id = song_a_rs.song_id
    if @overrated_ids.include?(id)
      # overrated: match against lower-ranked — losing to a weaker song is unexpected, causing a bigger ELO drop
      opponent_rs.elo_score > song_a_rs.elo_score
    elsif @underrated_ids.include?(id)
      # underrated: match against higher-ranked — beating a stronger song is unexpected, causing a bigger ELO gain
      opponent_rs.elo_score < song_a_rs.elo_score
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

class ChallengePackService
  PACK_SIZE = 5

  def self.call(ranking, song_id, flag_type)
    new(ranking, song_id, flag_type).call
  end

  def initialize(ranking, song_id, flag_type)
    @ranking   = ranking
    @song_id   = song_id.to_i
    @flag_type = flag_type.to_sym
  end

  def call
    ranking_songs = @ranking.ranking_songs.includes(:song).to_a
    song_a_rs     = ranking_songs.find { |rs| rs.song_id == @song_id }
    return [] unless song_a_rs

    pool = opponent_pool(song_a_rs, ranking_songs)
    select_pack(song_a_rs, pool)
  end

  private

  def opponent_pool(song_a_rs, ranking_songs)
    case @flag_type
    when :underrated
      ranking_songs.select { |rs| rs.elo_score > song_a_rs.elo_score }
    when :overrated
      ranking_songs.select { |rs| rs.elo_score < song_a_rs.elo_score }
    when :unsure
      ranking_songs.reject { |rs| rs.song_id == @song_id }
    else
      []
    end
  end

  def select_pack(song_a_rs, pool)
    pairs     = []
    remaining = pool.dup
    [ PACK_SIZE, pool.size ].min.times do
      break if remaining.empty?
      song_b_rs = sample_by_proximity(remaining, song_a_rs)
      pairs << { song_a: song_a_rs.song, song_b: song_b_rs.song }
      remaining.delete(song_b_rs)
    end
    pairs
  end

  def sample_by_proximity(candidates, song_a_rs)
    weights = candidates.map do |rs|
      elo_diff = (rs.elo_score - song_a_rs.elo_score).abs
      Math.exp(-elo_diff / 100.0)
    end
    total      = weights.sum
    r          = rand * total
    cumulative = 0.0
    candidates.each_with_index do |rs, i|
      cumulative += weights[i]
      return rs if cumulative >= r
    end
    candidates.last
  end
end

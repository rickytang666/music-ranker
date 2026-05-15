require 'rails_helper'

RSpec.describe MatchupSelectorService do
  # helper: add n songs to a ranking with sequential ELO scores
  def add_songs(ranking, count:, elo_start: 1000, elo_step: 50)
    count.times.map do |i|
      create(:ranking_song, ranking: ranking, elo_score: elo_start + (i * elo_step))
    end
  end

  let(:ranking) { create(:ranking) }

  def call(signals = {}, excluded_pairs: [])
    MatchupSelectorService.call(ranking, signals, excluded_pairs: excluded_pairs)
  end

  # ── basic constraints ────────────────────────────────────────────────────────

  context "with fewer than 2 songs" do
    it "returns nil with 0 songs" do
      expect(call).to be_nil
    end

    it "returns nil with 1 song" do
      create(:ranking_song, ranking: ranking)
      expect(call).to be_nil
    end
  end

  context "with 2 or more songs" do
    before { add_songs(ranking, count: 5) }

    it "returns a matchup with song_a and song_b" do
      result = call
      expect(result).to include(:song_a, :song_b)
    end

    it "never matches a song against itself" do
      50.times do
        result = call
        expect(result[:song_a].id).not_to eq(result[:song_b].id)
      end
    end
  end

  # ── excluded pairs ───────────────────────────────────────────────────────────

  context "excluded pairs" do
    it "never returns an excluded pair" do
      songs = add_songs(ranking, count: 3)
      a, b = songs[0].song_id, songs[1].song_id

      20.times do
        result = call(excluded_pairs: [ [ a, b ] ])
        ids = [ result[:song_a].id, result[:song_b].id ].sort
        expect(ids).not_to eq([ a, b ].sort)
      end
    end

    it "falls back when all pairs of a song are excluded" do
      songs = add_songs(ranking, count: 3)
      # exclude every possible pairing involving songs[0]
      excluded = songs[1..].map { |rs| [ songs[0].song_id, rs.song_id ] }
      result = call(excluded_pairs: excluded)
      expect(result).not_to be_nil
    end
  end

  # ── underrated constraint ────────────────────────────────────────────────────

  context "when song is flagged as underrated" do
    it "never picks an opponent with lower ELO" do
      songs = add_songs(ranking, count: 10, elo_start: 1000, elo_step: 50)
      # flag the lowest-ELO song as underrated (rank 10 of 10)
      underrated_id = songs.min_by(&:elo_score).song_id

      50.times do
        result = call({ underrated_ids: [ underrated_id ] })
        # song_a should be the underrated song; song_b must be higher ELO
        next unless result[:song_a].id == underrated_id
        opponent = ranking.ranking_songs.find_by!(song_id: result[:song_b].id)
        underrated_rs = ranking.ranking_songs.find_by!(song_id: underrated_id)
        expect(opponent.elo_score).to be > underrated_rs.elo_score
      end
    end
  end

  # ── overrated constraint ─────────────────────────────────────────────────────

  context "when song is flagged as overrated" do
    it "never picks an opponent with higher ELO" do
      songs = add_songs(ranking, count: 10, elo_start: 1000, elo_step: 50)
      # flag the highest-ELO song as overrated (rank 1 of 10)
      overrated_id = songs.max_by(&:elo_score).song_id

      50.times do
        result = call({ overrated_ids: [ overrated_id ] })
        next unless result[:song_a].id == overrated_id
        opponent = ranking.ranking_songs.find_by!(song_id: result[:song_b].id)
        overrated_rs = ranking.ranking_songs.find_by!(song_id: overrated_id)
        expect(opponent.elo_score).to be < overrated_rs.elo_score
      end
    end
  end

  # ── fallback when constraints can't be met ───────────────────────────────────

  context "fallback behavior" do
    it "still returns a matchup when the underrated song is already rank 1" do
      songs = add_songs(ranking, count: 5, elo_start: 1000, elo_step: 50)
      top_id = songs.max_by(&:elo_score).song_id
      # flagging rank 1 as underrated — no one above, should fallback gracefully
      expect(call({ underrated_ids: [ top_id ] })).not_to be_nil
    end

    it "still returns a matchup when the overrated song is already last" do
      songs = add_songs(ranking, count: 5, elo_start: 1000, elo_step: 50)
      bottom_id = songs.min_by(&:elo_score).song_id
      expect(call({ overrated_ids: [ bottom_id ] })).not_to be_nil
    end
  end
end

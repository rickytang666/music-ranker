require 'rails_helper'

RSpec.describe MatchupSelectorService do
  def add_songs(ranking, count:, elo_start: 1000, elo_step: 50)
    count.times.map do |i|
      create(:ranking_song, ranking: ranking, elo_score: elo_start + (i * elo_step))
    end
  end

  let(:ranking) { create(:ranking) }

  def call(excluded_pairs: [])
    MatchupSelectorService.call(ranking, excluded_pairs: excluded_pairs)
  end

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
      expect(call).to include(:song_a, :song_b)
    end

    it "never matches a song against itself" do
      50.times do
        result = call
        expect(result[:song_a].id).not_to eq(result[:song_b].id)
      end
    end
  end

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

    it "falls back when all pairs involving a song are excluded" do
      songs = add_songs(ranking, count: 3)
      excluded = songs[1..].map { |rs| [ songs[0].song_id, rs.song_id ] }
      expect(call(excluded_pairs: excluded)).not_to be_nil
    end
  end
end

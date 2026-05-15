require 'rails_helper'

RSpec.describe ChallengePackService do
  def add_songs(ranking, count:, elo_start: 1000, elo_step: 50)
    count.times.map do |i|
      create(:ranking_song, ranking: ranking, elo_score: elo_start + (i * elo_step))
    end
  end

  let(:ranking) { create(:ranking) }

  def call(song_id, flag_type)
    ChallengePackService.call(ranking, song_id, flag_type)
  end

  context "underrated" do
    it "returns up to 5 pairs with song_a fixed as the flagged song" do
      songs = add_songs(ranking, count: 10)
      flagged = songs.min_by(&:elo_score)
      pairs = call(flagged.song_id, "underrated")
      expect(pairs.size).to be_between(1, 5)
      pairs.each { |p| expect(p[:song_a].id).to eq(flagged.song_id) }
    end

    it "only picks opponents with higher ELO" do
      songs = add_songs(ranking, count: 10)
      flagged = songs.min_by(&:elo_score)
      pairs = call(flagged.song_id, "underrated")
      flagged_elo = flagged.elo_score
      pairs.each do |p|
        opponent = ranking.ranking_songs.find_by!(song_id: p[:song_b].id)
        expect(opponent.elo_score).to be > flagged_elo
      end
    end

    it "returns no duplicate opponents" do
      songs = add_songs(ranking, count: 10)
      flagged = songs.min_by(&:elo_score)
      pairs = call(flagged.song_id, "underrated")
      song_b_ids = pairs.map { |p| p[:song_b].id }
      expect(song_b_ids).to eq(song_b_ids.uniq)
    end

    it "returns min(available, 5) when fewer opponents exist" do
      songs = add_songs(ranking, count: 3)
      flagged = songs.min_by(&:elo_score)
      pairs = call(flagged.song_id, "underrated")
      # only 2 songs above the lowest
      expect(pairs.size).to eq(2)
    end

    it "returns empty when already rank 1" do
      songs = add_songs(ranking, count: 5)
      top = songs.max_by(&:elo_score)
      expect(call(top.song_id, "underrated")).to be_empty
    end
  end

  context "overrated" do
    it "only picks opponents with lower ELO" do
      songs = add_songs(ranking, count: 10)
      flagged = songs.max_by(&:elo_score)
      pairs = call(flagged.song_id, "overrated")
      flagged_elo = flagged.elo_score
      pairs.each do |p|
        opponent = ranking.ranking_songs.find_by!(song_id: p[:song_b].id)
        expect(opponent.elo_score).to be < flagged_elo
      end
    end

    it "returns empty when already last" do
      songs = add_songs(ranking, count: 5)
      bottom = songs.min_by(&:elo_score)
      expect(call(bottom.song_id, "overrated")).to be_empty
    end
  end

  context "unsure" do
    it "picks opponents from both above and below" do
      songs = add_songs(ranking, count: 10)
      mid = songs[4]
      pairs = call(mid.song_id, "unsure")
      expect(pairs.size).to be_between(1, 5)
      pairs.each { |p| expect(p[:song_b].id).not_to eq(mid.song_id) }
    end
  end
end

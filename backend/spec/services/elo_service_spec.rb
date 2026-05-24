require 'rails_helper'

RSpec.describe EloService do
  let(:ranking) { create(:ranking) }
  let(:winner_rs) { create(:ranking_song, ranking: ranking, elo_score: 1600.0, matchup_count: 10) }
  let(:loser_rs) { create(:ranking_song, ranking: ranking, elo_score: 1200.0, matchup_count: 10) }

  # more balanced matchup for confidence testing
  let(:balanced_winner_rs) { create(:ranking_song, ranking: ranking, elo_score: 1550.0, matchup_count: 10) }
  let(:balanced_loser_rs) { create(:ranking_song, ranking: ranking, elo_score: 1500.0, matchup_count: 10) }

  def call_service(confidence: 1.0)
    EloService.call(winner_rs, loser_rs, confidence: confidence)
    winner_rs.reload
    loser_rs.reload
  end

  describe "confidence-based ELO adjustment" do
    context "with 100% confidence (binary, 1.0)" do
      it "produces ELO swings similar to original system" do
        initial_winner_elo = winner_rs.elo_score
        initial_loser_elo = loser_rs.elo_score

        call_service(confidence: 1.0)

        expect(winner_rs.elo_score).to be > initial_winner_elo
        expect(loser_rs.elo_score).to be < initial_loser_elo
      end

      it "transfers equal ELO between winner and loser" do
        call_service(confidence: 1.0)

        winner_gain = winner_rs.elo_score - 1600.0
        loser_loss = 1200.0 - loser_rs.elo_score

        expect(winner_gain).to be_within(0.01).of(loser_loss)
      end
    end

    context "with 90-10 confidence" do
      it "produces larger swings than 50-50" do
        swings_90_10 = []
        3.times do
          call_service(confidence: 0.90)
          swings_90_10 << (winner_rs.elo_score - 1600.0).abs
          winner_rs.update!(elo_score: 1600.0)
        end

        swings_50_50 = []
        3.times do
          call_service(confidence: 0.50)
          swings_50_50 << (winner_rs.elo_score - 1600.0).abs
          winner_rs.update!(elo_score: 1600.0)
        end

        expect(swings_90_10.sum).to be > swings_50_50.sum
      end
    end

    context "with 50-50 confidence (equal preference)" do
      it "produces no ELO change" do
        initial_winner_elo = winner_rs.elo_score
        initial_loser_elo = loser_rs.elo_score

        call_service(confidence: 0.50)

        expect(winner_rs.elo_score).to eq(initial_winner_elo)
        expect(loser_rs.elo_score).to eq(initial_loser_elo)
      end
    end

    context "with variable confidence values" do
      it "produces zero change at exactly 50% confidence" do
        [0.5].each do |conf|
          winner_rs.update!(elo_score: 1600.0)
          loser_rs.update!(elo_score: 1200.0)

          call_service(confidence: conf)

          expect(winner_rs.elo_score).to eq(1600.0)
          expect(loser_rs.elo_score).to eq(1200.0)
        end
      end

      it "produces larger swings at higher confidence than lower confidence" do
        # use balanced matchup (1550 vs 1500) where expected_score is close to 0.5
        # compare 0.9 vs 0.6
        swings_09 = []
        3.times do
          balanced_winner_rs.update!(elo_score: 1550.0)
          balanced_loser_rs.update!(elo_score: 1500.0)
          EloService.call(balanced_winner_rs, balanced_loser_rs, confidence: 0.90)
          balanced_winner_rs.reload
          swings_09 << (balanced_winner_rs.elo_score - 1550.0).abs
        end

        swings_06 = []
        3.times do
          balanced_winner_rs.update!(elo_score: 1550.0)
          balanced_loser_rs.update!(elo_score: 1500.0)
          EloService.call(balanced_winner_rs, balanced_loser_rs, confidence: 0.60)
          balanced_winner_rs.reload
          swings_06 << (balanced_winner_rs.elo_score - 1550.0).abs
        end

        expect(swings_09.sum).to be > swings_06.sum
      end
    end

    context "with provisional K (fewer than 10 matchups)" do
      let(:new_player_rs) { create(:ranking_song, ranking: ranking, elo_score: 1600.0, matchup_count: 5) }

      it "uses higher K value (64 vs 32) in base calculation" do
        established_winner = winner_rs
        established_loser = loser_rs

        new_winner = create(:ranking_song, ranking: ranking, elo_score: 1600.0, matchup_count: 5)
        new_loser = create(:ranking_song, ranking: ranking, elo_score: 1200.0, matchup_count: 5)

        EloService.call(established_winner, established_loser, confidence: 1.0)
        established_winner.reload
        established_loser.reload
        est_swing = (established_winner.elo_score - 1600.0).abs

        established_winner.update!(elo_score: 1600.0)
        established_loser.update!(elo_score: 1200.0)

        EloService.call(new_winner, new_loser, confidence: 1.0)
        new_winner.reload
        new_loser.reload
        new_swing = (new_winner.elo_score - 1600.0).abs

        expect(new_swing).to be > est_swing
      end
    end

    context "matchup_count increment" do
      it "increments matchup_count for both songs" do
        initial_winner_count = winner_rs.matchup_count
        initial_loser_count = loser_rs.matchup_count

        call_service

        expect(winner_rs.matchup_count).to eq(initial_winner_count + 1)
        expect(loser_rs.matchup_count).to eq(initial_loser_count + 1)
      end
    end
  end
end

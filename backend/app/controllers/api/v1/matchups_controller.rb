module Api
  module V1
    class MatchupsController < BaseController
      wrap_parameters false
      before_action :set_ranking

      def next
        excluded = params[:skip_pairs].to_s.split(";").filter_map do |pair|
          ids = pair.split(",").map(&:to_i)
          ids.length == 2 ? ids : nil
        end
        result = MatchupSelectorService.call(@ranking, excluded_pairs: excluded)
        return render json: { error: "not enough songs" }, status: :unprocessable_entity unless result

        render json: { song_a: song_json(result[:song_a]), song_b: song_json(result[:song_b]) }
      end

      def challenge
        song_id   = params.require(:song_id).to_i
        flag_type = params.require(:flag_type)

        pairs = ChallengePackService.call(@ranking, song_id, flag_type)
        render json: pairs.map { |p| { song_a: song_json(p[:song_a]), song_b: song_json(p[:song_b]) } }
      end

      def create
        winner = @ranking.songs.find(matchup_params[:winner_id])
        song_a = @ranking.songs.find(matchup_params[:song_a_id])
        song_b = @ranking.songs.find(matchup_params[:song_b_id])
        loser  = winner == song_a ? song_b : song_a

        matchup = @ranking.matchups.create!(
          song_a: song_a,
          song_b: song_b,
          winner: winner,
          played_at: Time.current,
          confidence: matchup_params[:confidence] || 1.0
        )

        winner_rs = @ranking.ranking_songs.find_by!(song: winner)
        loser_rs  = @ranking.ranking_songs.find_by!(song: loser)
        EloService.call(winner_rs, loser_rs, confidence: matchup.confidence)

        render json: { matchup_id: matchup.id }, status: :created
      end

      private

      def set_ranking
        @ranking = current_user.rankings.find(params[:ranking_id])
      end

      def matchup_params
        params.require(:matchup).permit(:song_a_id, :song_b_id, :winner_id, :confidence)
      end

      def song_json(song)
        song.as_json(only: [ :id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url ])
      end
    end
  end
end

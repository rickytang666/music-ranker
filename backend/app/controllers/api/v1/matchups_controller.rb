module Api
  module V1
    class MatchupsController < BaseController
      wrap_parameters false
      before_action :set_ranking

      def next
        result = MatchupSelectorService.call(@ranking, signal_params)
        return render json: { error: "not enough songs" }, status: :unprocessable_entity unless result

        render json: {
          song_a: song_json(result[:song_a]),
          song_b: song_json(result[:song_b])
        }
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
          played_at: Time.current
        )

        winner_rs = @ranking.ranking_songs.find_by!(song: winner)
        loser_rs  = @ranking.ranking_songs.find_by!(song: loser)
        EloService.call(winner_rs, loser_rs)

        render json: { matchup_id: matchup.id }, status: :created
      end

      private

      def set_ranking
        @ranking = current_user.rankings.find(params[:ranking_id])
      end

      def signal_params
        params.permit(overrated_ids: [], underrated_ids: [], unsure_ids: [])
      end

      def matchup_params
        params.require(:matchup).permit(:song_a_id, :song_b_id, :winner_id)
      end

      def song_json(song)
        song.as_json(only: [:id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url])
      end
    end
  end
end

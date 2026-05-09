module Api
  module V1
    class SongsController < BaseController
      before_action :set_ranking

      def index
        songs = @ranking.ranking_songs
                        .includes(:song)
                        .order(elo_score: :desc)
                        .sort_by { |rs| [-rs.elo_score, -(rs.song.release_date || "0").tr('-', '').to_i] }
                        .map do |rs|
          rs.song.as_json(only: [:id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url])
            .merge(elo_score: rs.elo_score, matchup_count: rs.matchup_count)
        end
        render json: songs
      end

      def create
        song_ids = params.require(:song_ids)
        songs = Song.where(id: song_ids)

        added = songs.filter_map do |song|
          RankingSong.find_or_create_by(ranking: @ranking, song: song)
        end

        render json: { added: added.count }, status: :created
      end

      def destroy
        ranking_song = @ranking.ranking_songs.find_by!(song_id: params[:id])
        ranking_song.destroy
        head :no_content
      end

      private

      def set_ranking
        @ranking = current_user.rankings.find(params[:ranking_id])
      end
    end
  end
end

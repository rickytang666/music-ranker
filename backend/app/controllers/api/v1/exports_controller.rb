module Api
  module V1
    class ExportsController < BaseController
      def show
        ranking = current_user.rankings.find(params[:ranking_id])
        songs = ranking.ranking_songs
                       .includes(:song)
                       .order(elo_score: :desc)
                       .map.with_index(1) do |rs, rank|
          { rank: rank, title: rs.song.title, artist: rs.song.artist_name, album: rs.song.album_name }
        end

        respond_to do |format|
          format.json { render json: songs }
          format.text { render plain: songs.map { |s| "#{s[:rank]}. #{s[:title]} — #{s[:artist]}" }.join("\n") }
        end
      end
    end
  end
end

module Api
  module V1
    class ExportsController < BaseController
      def show
        ranking = current_user.rankings.find(params[:ranking_id])
        text = ranking.ranking_songs
                      .includes(:song)
                      .order(elo_score: :desc)
                      .each_with_index
                      .map { |rs, i| "#{i + 1}. #{rs.song.title} — #{rs.song.artist_name}" }
                      .join("\n")
        render plain: text
      end

      def spotify
        ranking = current_user.rankings.find(params[:ranking_id])
        name    = params[:name].presence || ranking.name
        count   = (params[:count] || ranking.spotify_last_export_count || 20).to_i.clamp(1, ranking.ranking_songs.count)
        public  = ActiveModel::Type::Boolean.new.cast(params[:public]) || false

        result = SpotifyExportService.call(current_user, ranking, name: name, count: count, public: public)
        render json: result
      rescue => e
        if e.message.include?("403")
          render json: { error: "spotify_scope_required" }, status: :forbidden
        else
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end

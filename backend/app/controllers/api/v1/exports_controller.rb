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
        ranking   = current_user.rankings.find(params[:ranking_id])
        name      = params[:name].presence || ranking.name
        count     = (params[:count] || ranking.spotify_last_export_count || 20).to_i.clamp(1, ranking.ranking_songs.count)
        is_public = ActiveModel::Type::Boolean.new.cast(params[:public]) || false

        result = SpotifyExportService.call(current_user, ranking, name: name, count: count, public: is_public)
        ranking.update_column(:spotify_sync_error, false) if ranking.spotify_sync_error?
        render json: result
      rescue => e
        Rails.logger.error "spotify export error: #{e.class}: #{e.message}"
        render_spotify_error(e)
      end

      private

      def render_spotify_error(e)
        case e
        when SpotifyClient::ForbiddenError
          render json: { error: "spotify_scope_required" }, status: :forbidden
        when SpotifyClient::ServiceUnavailableError
          render json: { error: "spotify is temporarily unavailable, try again in a moment" }, status: :service_unavailable
        when SpotifyClient::RateLimitError, SpotifyClient::NotFoundError
          render json: { error: e.message }, status: :unprocessable_entity
        else
          # anything else carries internal detail, it is already logged above
          render json: { error: "export failed, try again" }, status: :unprocessable_entity
        end
      end
    end
  end
end

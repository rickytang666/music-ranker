module Api
  module V1
    class SpotifyController < BaseController
      rescue_from SpotifyClient::RateLimitError, with: :rate_limited
      def search_artists
        results = importer.search_artists(params.require(:q))
        render json: results
      end

      def search_albums
        results = importer.search_albums(params.require(:q))
        render json: results
      end

      def search_tracks
        songs = importer.search_tracks(params.require(:q))
        render json: songs.map { |s| s.as_json(only: [:id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url]) }
      end

      def artist_albums
        results = importer.artist_albums(params[:id])
        render json: results
      end

      def artist_tracks
        songs = importer.import_artist_tracks(params[:id])
        render json: songs.map { |s| s.as_json(only: [:id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url]) }
      end

      def album_tracks
        album = {
          "name"         => params[:name],
          "images"       => params[:art].present? ? [{ "url" => params[:art] }] : [],
          "release_date" => params[:release_date]
        }
        songs = importer.import_album_tracks(params[:id], album: album)
        render json: songs.map { |s| s.as_json(only: [:id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url]) }
      end

      private

      def importer
        @importer ||= SpotifyImporterService.new(current_user)
      end

      def rate_limited(err)
        render json: { error: err.message }, status: :too_many_requests
      end
    end
  end
end

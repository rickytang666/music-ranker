module Api
  module V1
    class SpotifyController < BaseController
      def search_artists
        results = importer.search_artists(params.require(:q))
        render json: results
      end

      def artist_tracks
        songs = importer.import_artist_tracks(params[:id])
        render json: songs.map { |s| s.as_json(only: [:id, :spotify_track_id, :title, :artist_name, :album_name, :album_art_url]) }
      end

      def search_tracks
        results = importer.search_tracks(params.require(:q))
        render json: results
      end

      private

      def importer
        @importer ||= SpotifyImporterService.new(current_user)
      end
    end
  end
end

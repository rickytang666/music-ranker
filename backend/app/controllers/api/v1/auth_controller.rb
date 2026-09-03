module Api
  module V1
    class AuthController < BaseController
      def me
        render json: {
          id: current_user.id,
          spotify_id: current_user.spotify_id,
          display_name: current_user.display_name,
          image_url: current_user.image_url
        }
      end

      def logout
        head :no_content
      end
    end
  end
end

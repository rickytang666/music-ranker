module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate!

      def me
        render json: {
          id: current_user.id,
          spotify_id: current_user.spotify_id,
          display_name: current_user.display_name
        }
      end

      def logout
        head :no_content
      end
    end
  end
end

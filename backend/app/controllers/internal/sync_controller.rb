module Internal
  class SyncController < ApplicationController
    before_action :authenticate_internal!

    def rankings
      SpotifySyncService.call
      head :ok
    end

    private

    def authenticate_internal!
      secret = ENV["INTERNAL_SYNC_SECRET"]
      token  = request.headers["Authorization"]&.split(" ")&.last
      render json: { error: "unauthorized" }, status: :unauthorized unless secret.present? && token == secret
    end
  end
end

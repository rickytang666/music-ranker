class ApplicationController < ActionController::API
  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = token && JsonWebToken.decode(token)
    @current_user = payload && User.find_by(id: payload[:user_id])
    render json: { error: "unauthorized" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end

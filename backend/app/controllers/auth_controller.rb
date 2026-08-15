class AuthController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    user = User.find_or_initialize_by(spotify_id: auth.uid)
    user.update!(
      display_name: auth.info.name,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token.presence || user.refresh_token,
      token_expires_at: Time.at(auth.credentials.expires_at),
      spotify_market: auth.extra.raw_info["country"]
    )
    # no refresh token fails silently later, once the access token expires
    Rails.logger.warn "auth callback: user #{user.id} has no refresh token" if user.refresh_token.blank?
    Rails.logger.info "auth callback ok: user #{user.id} market=#{user.spotify_market || "none"}"

    token = JsonWebToken.encode(user_id: user.id)
    redirect_to "#{ENV.fetch("FRONTEND_ORIGIN")}/auth/callback?token=#{token}", allow_other_host: true
  end

  def failure
    Rails.logger.warn "auth failure: #{params[:message].presence || "no message"} strategy=#{params[:strategy].presence || "unknown"}"
    redirect_to "#{ENV.fetch("FRONTEND_ORIGIN")}/auth/error", allow_other_host: true
  end
end

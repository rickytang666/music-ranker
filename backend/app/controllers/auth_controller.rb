class AuthController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    user = User.find_or_initialize_by(spotify_id: auth.uid)
    user.update!(
      display_name: auth.info.name,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      token_expires_at: Time.at(auth.credentials.expires_at),
      spotify_market: auth.extra.raw_info["country"]
    )
    token = JsonWebToken.encode(user_id: user.id)
    redirect_to "#{ENV.fetch("FRONTEND_ORIGIN")}/auth/callback?token=#{token}", allow_other_host: true
  end

  def failure
    redirect_to "#{ENV.fetch("FRONTEND_ORIGIN")}/auth/error", allow_other_host: true
  end
end

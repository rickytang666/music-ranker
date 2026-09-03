require "rails_helper"

# these errors used to fall through as an indistinguishable 500, which left the
# client unable to tell "no such artist" from "spotify is down"
RSpec.describe "spotify error mapping", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  {
    SpotifyClient::RateLimitError => :too_many_requests,
    SpotifyClient::ForbiddenError => :forbidden,
    SpotifyClient::NotFoundError => :not_found,
    SpotifyClient::ServiceUnavailableError => :service_unavailable
  }.each do |error, status|
    it "maps #{error} to #{status}" do
      allow_any_instance_of(SpotifyImporterService)
        .to receive(:search_artists).and_raise(error, "boom")

      get "/api/v1/spotify/search/artists", params: { q: "anything" }, headers: headers

      expect(response).to have_http_status(status)
      expect(response.parsed_body["error"]).to eq("boom")
    end
  end
end

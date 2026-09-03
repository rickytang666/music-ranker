require "rails_helper"

# these all used to surface as one indistinguishable 500, hiding "no such artist" behind "spotify is down"
RSpec.describe "spotify error mapping", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  {
    SpotifyClient::RateLimitError => :too_many_requests,
    SpotifyClient::ForbiddenError => :forbidden,
    SpotifyClient::NotFoundError => :not_found,
    SpotifyClient::ServiceUnavailableError => :service_unavailable
  }.each do |error_class, status|
    it "maps #{error_class} to #{status}" do
      allow_any_instance_of(SpotifyImporterService)
        .to receive(:search_artists).and_raise(error_class, "boom")

      get "/api/v1/spotify/search/artists", params: { q: "anything" }, headers: headers

      expect(response).to have_http_status(status)
      expect(response.parsed_body["error"]).to eq("boom")
    end
  end
end

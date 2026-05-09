module Api
  module V1
    class ExportsController < BaseController
      def show
        ranking = current_user.rankings.find(params[:ranking_id])
        text = ranking.ranking_songs
                      .includes(:song)
                      .order(elo_score: :desc)
                      .each_with_index
                      .map { |rs, i| "#{i + 1}. #{rs.song.title} — #{rs.song.artist_name}" }
                      .join("\n")
        render plain: text
      end
    end
  end
end

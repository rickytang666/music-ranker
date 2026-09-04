module Api
  module V1
    class RankingsController < BaseController
      before_action :set_ranking, only: [:update, :destroy, :reset]

      RANKING_FIELDS = [:id, :name, :created_at, :spotify_playlist_id, :spotify_last_export_count, :spotify_sync_count, :spotify_sync_error].freeze

      def index
        # counts aggregated in sql; per-record counts would be n+1 in the number of rankings.
        # matchups is deliberately not joined: Matchup#purge_overflow caps that table at
        # QUEUE_CAP rows, so counting it saturates. elo_service increments both songs of a
        # matchup, so halving the ranking_songs total recovers the real figure and matches
        # what the reset dialog shows.
        rankings = current_user.rankings
                               .left_joins(:ranking_songs)
                               .select(
                                 "rankings.*",
                                 "COUNT(ranking_songs.id) AS song_count",
                                 "ROUND(COALESCE(SUM(ranking_songs.matchup_count), 0) / 2.0) AS matchup_count"
                               )
                               .group("rankings.id")
                               .order(created_at: :desc)

        render json: rankings.map { |ranking|
          serialize(ranking, ranking.song_count, ranking.matchup_count)
        }
      end

      def create
        ranking = current_user.rankings.build(ranking_params)
        if ranking.save
          render json: serialize(ranking, *counts_for(ranking)), status: :created
        else
          render json: { errors: ranking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @ranking.update(ranking_params)
          render json: serialize(@ranking, *counts_for(@ranking))
        else
          render json: { errors: @ranking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @ranking.destroy
        head :no_content
      end

      def reset
        @ranking.ranking_songs.update_all(elo_score: RankingSong::DEFAULT_ELO, matchup_count: 0)
        @ranking.matchups.delete_all
        head :no_content
      end

      private

      # every response carrying a ranking includes counts; the client store treats them
      # as required and replaces records wholesale on update
      def serialize(ranking, song_count, matchup_count)
        ranking.as_json(only: RANKING_FIELDS)
               .merge("song_count" => song_count.to_i, "matchup_count" => matchup_count.to_i)
      end

      def counts_for(ranking)
        [ranking.ranking_songs.count, (ranking.ranking_songs.sum(:matchup_count) / 2.0).round]
      end

      def set_ranking
        @ranking = current_user.rankings.find(params[:id])
      end

      def ranking_params
        params.require(:ranking).permit(:name, :spotify_sync_count)
      end
    end
  end
end

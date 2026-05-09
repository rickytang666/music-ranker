module Api
  module V1
    class RankingsController < BaseController
      before_action :set_ranking, only: [:update, :destroy]

      def index
        rankings = current_user.rankings.order(created_at: :desc)
        render json: rankings.as_json(only: [:id, :name, :created_at])
      end

      def create
        ranking = current_user.rankings.build(ranking_params)
        if ranking.save
          render json: ranking.as_json(only: [:id, :name, :created_at]), status: :created
        else
          render json: { errors: ranking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @ranking.update(ranking_params)
          render json: @ranking.as_json(only: [:id, :name, :created_at])
        else
          render json: { errors: @ranking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @ranking.destroy
        head :no_content
      end

      private

      def set_ranking
        @ranking = current_user.rankings.find(params[:id])
      end

      def ranking_params
        params.require(:ranking).permit(:name)
      end
    end
  end
end

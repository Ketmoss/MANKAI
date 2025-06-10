class ReviewsController < ApplicationController
before_action :set_dbmanga, only: %i[new create]

  def new
    @review = Review.new
  end

  def create
    @review = Review.new(review_params)
    @review.db_manga = @dbmanga
    if @review.save
      redirect_to db_manga_path(@dbmanga)
    else
      render :new, status: :unprocessable_entity
    end
  end

def show
@review = Review.find(params[:id])
end

def destroy
    @review = Review.find(params[:id])
    @review.destroy
    redirect_to db_manga_path(@review.db_manga), status: :see_other
  end

  private

  def set_dbmanga
    @manga = DbManga.find(params[:db_manga_id])
  end

  def review_params
    params.require(:review).permit(:content, :score)
  end
end

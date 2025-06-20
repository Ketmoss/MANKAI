class ReviewsController < ApplicationController
before_action :set_dbmanga, only: %i[new create]

  def index
    @reviews = Review.all
  end

  def new
    @review = Review.new
    @page_title = "Donne ton avis"
  end

  def create
    @review = Review.new(review_params)
    @review.user = current_user
    @review.db_manga = @dbmanga
    if @review.save!
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
    @dbmanga = DbManga.find(params[:db_manga_id])
  end

  def review_params
    params.require(:review).permit(:content, :score)
  end
end

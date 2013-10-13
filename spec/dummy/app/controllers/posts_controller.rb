class PostsController < ApplicationController
  presents :post, :with => StrongPresenter::Presenter, :only => :show
  presents :post, :with => PostPresenter, :only => :show do |presenter|
    presenter.permit(:permit_to_present, :peek_a_boo)
  end
  presents :post, :with => StrongPresenter::Presenter, :only => [:index]
  presents :post, :with => StrongPresenter::Presenter, :except => [:show, :new]

  def show
    @post = Post.find(params[:id])
  end

  def mail
    post = Post.find(params[:id])
    email = PostMailer.presented_email(post).deliver
    render text: email.body
  end

  private

  def goodnight_moon
    "Goodnight, moon!"
  end
  helper_method :goodnight_moon
end

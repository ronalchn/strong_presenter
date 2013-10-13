class PostMailer < ApplicationMailer
  default from: "from@example.com"
  layout "application"

  # Mailers don't import app/helpers automatically
  helper :application

  def presented_email(post)
    @post = PostPresenter.new(post).permit!
    mail to: "to@example.com", subject: "A presented post"
  end

  private

  def goodnight_moon
    "Goodnight, moon!"
  end
  helper_method :goodnight_moon
end

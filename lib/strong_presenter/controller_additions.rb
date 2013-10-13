module StrongPresenter
  module ControllerAdditions
    extend ActiveSupport::Concern

    module ClassMethods
      # @overload presents(*variables, options = {})
      #   Defines a helper method to access instance variables wrapped in presenters.
      #
      #   @example
      #     # app/controllers/articles_controller.rb
      #     class ArticlesController < ApplicationController
      #       presents :article
      #       presents :comments, with: ArticleCommentsPresenter, only: :show
      #       presents :comments, with: CommentsPresenter, only: :index { |presenter| presenter.permit(:author, :text) }
      #
      #       def show
      #         @article = Article.find(params[:id])
      #       end
      #     end
      #
      #     # app/views/articles/show.html.erb
      #     <%= article.presented_title %>
      #
      #   @param [Symbols*] variables
      #     names of the instance variables to present (without the `@`).
      #   @param [Hash] options
      #   @option options [Presenter, CollectionPresenter] :with (nil)
      #     presenter class to use. If nil, it is inferred from the instance
      #     variable.
      #   @option options [Symbols*] :only (nil)
      #     apply presenter only on these controller actions.
      #   @option options [Symbols*] :except (nil)
      #     don't apply presenter on these controller actions.
      #   @yield [Presenter] code to execute when presenter is initialized
      def presents(*variables, &block)
        options = variables.extract_options!
        options.assert_valid_keys(:with, :only, :except)

        constructor = StrongPresenter::PresenterHelperConstructor.new(self, block, options)

        variables.each do |variable|
          constructor.call(variable)
          helper_method variable
        end
      end

    end
  end
end


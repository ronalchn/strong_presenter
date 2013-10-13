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

        factory = StrongPresenter::Factory.new(options.slice!(:only, :except))
        options.each { |k,v| options[k] = Array(v).map(&:to_sym) unless v.nil? }

        variables.each do |variable|
          object = "@#{variable}"
          presenter = "@#{variable}_presenter"

          shadowed_method = nil
          shadowed_method = instance_method variable if method_defined? variable # alias_method_chain without name pollution

          define_method variable do |*args|
            unless (options[:only].nil? || options[:only].include?(action_name.to_sym)) && 
                   (options[:except].nil? || !options[:except].include?(action_name.to_sym)) # scoped by controller action?
              return shadowed_method.bind(self).call(*args) if !shadowed_method.nil? # call old method if it existed
              raise NoMethodError # method does not exist
            end
            raise ArgumentError.new("wrong number of arguments (#{args.size} for 0)") unless args.empty?
            return instance_variable_get(presenter) if instance_variable_defined?(presenter)
            instance_variable_set presenter, factory.wrap(instance_variable_get(object)) { |presenter| self.instance_exec presenter, &block if block }
          end

          helper_method variable
        end
      end
    end
  end
end


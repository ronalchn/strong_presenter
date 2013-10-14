module StrongPresenter
  module Permissible
    extend ActiveSupport::Concern

    module ClassMethods
      # Permits all presenter attributes for presents, present & filter methods.
      def permit!
        define_method(:permitted_attributes){ @permitted_attributes ||= StrongPresenter::Permissions.new.permit_all! }
      end
    end

    # Permits given attributes. May be invoked multiple times.
    #
    # @example Each argument represents a single attribute:
    #   ArticlePresenter.new(@article).permit(:heading, :article)
    #
    # @example Attribute paths can be specified using symbol arrays. If an author name is normally accessed using @article.author.name:
    #   ArticlePresenter.new(@article).permit([:author, :name])
    #
    # @params [[Symbols*]*] attribute_paths
    #   the attributes to permit. An array of symbols represents an attribute path.
    # @return [self]
    def permit *attribute_paths
      permitted_attributes.permit permissions_prefix, *attribute_paths
      self
    end

    # Permits all presenter attributes for presents, present & filter methods.
    def permit!
      permitted_attributes.permit_all!
      self
    end

    # Selects the attributes given which have been permitted - an array of attributes. Attributes are
    # symbols, and attribute paths are arrays of symbols.
    #
    # @params [[Symbols*]*] attributes
    #   the attributes to check. An array of symbols represents an attribute path.
    # @return [[Symbols*]*] attribute (paths)
    def filter *attributes
      select_permitted(*attributes).map{ |attribute| attribute.first if attribute.size == 1 } # un-pack symbol if array with single symbol
    end

    protected
    def permitted_attributes
      @permitted_attributes ||= StrongPresenter::Permissions.new
    end

    def select_permitted *attribute_paths
      permitted_attributes.select_permitted permissions_prefix, *attribute_paths
    end

    private
    def permitted_attributes= permitted_attributes
      @permitted_attributes = permitted_attributes.merge @permitted_attributes
    end

    attr_writer :permissions_prefix
    def permissions_prefix
      @permissions_prefix ||= []
    end
  end
end


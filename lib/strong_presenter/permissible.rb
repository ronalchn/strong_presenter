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
    # @param [[Symbols*]*] attribute_paths
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
    # @param [Array<Symbol>*] attribute_paths
    #   the attribute paths to check. The attribute paths may also have arguments.
    # @return [Array<Array<Symbol>, Symbol>] attribute (paths)
    def filter *attribute_paths
      select_permitted(*attribute_paths).map{ |attribute| attribute.first if attribute.size == 1 } # un-pack symbol if array with single symbol
    end

    protected
    def permitted_attributes
      @permitted_attributes ||= StrongPresenter::Permissions.new
    end

    # Selects the attributes given which have been permitted - an array of attributes
    # Each returned attribute paths will be an array, even if it consists of only 1 symbol
    # @param [Array<Symbols>*] attribute_paths
    #   the attribute paths to check. The attribute paths may also have arguments.
    # @return [Array<Array<Symbol>>] attribute (paths)
    def select_permitted *attribute_paths
      permitted_attributes.select_permitted permissions_prefix, *attribute_paths
    end

    # Links presenter to permissions group of given presenter.
    # @param [Presenter] parent_presenter
    # @param [Array<Symbol>] relative_path
    #   The prefix prepended before every permission check relative to parent presenter.
    def link_permissions parent_presenter, relative_path = []
      self.permissions_prefix = parent_presenter.send(:permissions_prefix) + Array(relative_path)
      @permitted_attributes = parent_presenter.send(:permitted_attributes).merge @permitted_attributes, permissions_prefix
    end

    private
    attr_writer :permissions_prefix
    def permissions_prefix
      @permissions_prefix ||= []
    end
  end
end


module StrongPresenter
  # @private
  #
  #   Storage format:
  #     The permissions object is shared by collection presenters with its constituent presenters,
  #     and it is also shared with all of its associations. Each attribute path is stored as an array
  #     of symbols in a Set. There is one top level presenter - the one which initialized the
  #     Permissions object.
  #   
  #     When a presenter checks for permissions, the attribute path relative to the top
  #     presenter is prepended to each attribute path, and its existence checked in the Set.
  #
  #     Arguments can also be part of permissions control. They are simply additional elements in the attribute path array,
  #     and need not be symbols. If they are symbols, there is no way for Permissions to know whether they
  #     are part of the attribute path, or additional arguments. Only the presenter knows that.
  class Permissions

    # Checks whether everything is permitted.
    #
    # @return [Boolean]
    def complete?
      permitted_paths.include? [] and ((@permitted_paths = Set[[]] if permitted_paths.count > 1) or true)
    end

    # Permits everything
    #
    # @return self
    def permit_all!
      permitted_paths.clear
      permitted_paths << []
      self
    end

    # @overload permitted? prefix_path = nil, attribute_path
    #
    # Checks if the attribute path is permitted. This is the case if
    # any array prefix has been permitted.
    #
    # @param [Symbol, Array<Symbol>] prefix_path
    # @param [Symbol, Array<Symbol,Object>] attribute_path
    # @return [Boolean]
    def permitted? prefix_path, attribute_path = nil
      raw_permitted? Array(prefix_path), Array(attribute_path)
    end

    # Selects the attribute paths which are permitted.
    #
    # @param [Array] prefix_path
    #   namespace in which each of the given attribute paths are in
    # @param [[Symbol, Array<Symbol,Object>]*] *attribute_paths
    #   each attribute path is a symbol or array of symbols
    # @return [Array<Symbol, Array<Symbol,Object>>] array of attribute paths permitted
    def select_permitted prefix_path, *attribute_paths
      raw_select_permitted Array(prefix_path), nested_array(attribute_paths)
    end

    # Rejects the attribute paths which are permitted. Opposite of select_permitted.
    # Returns the attribute paths which are not permitted.
    #
    # @param [Array] prefix_path
    #   namespace in which each of the given attribute paths are in
    # @param [[Symbol, Array<Symbol,Object>]*] *attribute_paths
    #   each attribute path is a symbol or array of symbols
    # @return [Array<Symbol, Array<Symbol,Object>>] array of attribute paths remaining
    def reject_permitted prefix_path, *attribute_paths
      raw_reject_permitted Array(prefix_path), nested_array(attribute_paths)
    end

    # Permits some attribute paths
    #
    # @param [Array<Symbol>] prefix_path
    #   path to prepend to each attribute path
    # @param [[Symbol, Array<Symbol,Object>]*] *attribute_paths
    def permit prefix_path, *attribute_paths
      prefix_path = Array(prefix_path)
      # don't permit if already permitted
      raw_reject_permitted(prefix_path, nested_array(attribute_paths)).each do |attribute_path|
        permitted_paths << prefix_path + attribute_path
      end
      self
    end

    # Merges the permissions from another Permissions object
    #
    # @param [Permissions] permissions
    # @param [Array<Symbol>] prefix
    #   prefix to prepend to paths in permissions
    # @return self
    def merge permissions, prefix = []
      permitted_paths.merge permissions.permitted_paths.map{|path| prefix+path} if permissions.is_a? self.class
      self
    end

    protected

    def permitted_paths
      @permitted_paths ||= Set.new
    end

    private
    # We trust path parameters are arrays
    def raw_permitted? prefix_path, attribute_path = nil # const - does not alter arguments
      return true if complete?
      permitted_partial?([], prefix_path + Array(attribute_path))
    end

    def raw_reject_permitted prefix_path, attribute_paths # const - does not alter arguments
      return [] if raw_permitted? prefix_path
      attribute_paths.reject do |attribute_path|
        permitted_partial? prefix_path.dup, attribute_path
      end
    end

    def raw_select_permitted prefix_path, attribute_paths # const - does not alter arguments
      return attribute_paths if raw_permitted? prefix_path
      attribute_paths.select do |attribute_path|
        permitted_partial? prefix_path.dup, attribute_path
      end
    end

    # For internal use, checks if permitted explicitly by a subpath of [prefix_path, attribute_partial+]
    # where attribute_partial is a prefix of at least one symbol from attribute_part
    # Caution: Will mutate prefix_path
    def permitted_partial? prefix_path, attribute_path
      !!Array(attribute_path).detect do |attr|
        break unless attr.is_a? Symbol
        prefix_path << attr
        permitted_paths.include? prefix_path
      end
    end

    # Ensures that every array element is an array
    def nested_array array
      array.map{|e|Array(e)}
    end

  end
end

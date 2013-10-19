module StrongPresenter
  # @private
  #
  #   Storage format:
  #     Each attribute path is stored as an array of objects, usually strings in a Set. For indifferent access, 
  #     all symbols are converted to strings.
  #   
  #     Arguments can also be part of permissions control. They are simply additional elements in the attribute path array,
  #     and need not be strings or symbols. Permitting a string or symbol argument automatically permits both.
  #
  #     When checking if paths with tainted strings/elements are permitted, only exact matches are allowed
  class Permissions

    def prefix_path
      @prefix_path || []
    end

    # Initialize, optionally with link to permitted paths, and the prefix to that (with copy on write semantics)
    def initialize(permissions = nil, prefix_path = [])
      unless permissions.nil?
        @permitted_paths = permissions.permitted_paths
        @prefix_path = permissions.prefix_path + canonicalize(prefix_path) # copy on write
      end
    end

    # Checks whether everything is permitted. Considers :*, which permits all methods
    # but not association methods to be complete.
    # @return [Boolean]
    def complete?
      permitted? prefix_path + [:*]
    end

    # Permits wildcard method, but not association methods.
    # @return self
    def permit_all!
      copy_on_write!
      permitted_paths << [:*]
      self
    end

    # Checks if the attribute path is permitted. This is the case if
    # any array prefix has been permitted.
    # @param [Object, Array<Object>] prefix_path
    # @param [Object, Array<Object>] attribute_path
    # @return [Boolean]
    def permitted? attribute_path
      attribute_path = canonicalize(attribute_path)
      return true if permitted_paths.include? prefix_path + attribute_path # exact match
      !path_tainted?(attribute_path) and permitted_by_wildcard?(prefix_path + attribute_path)  # wildcard match only if not tainted
    end

    # Selects the attribute paths which are permitted.
    # @param [Array] prefix_path
    #   namespace in which each of the given attribute paths are in
    # @param [[Object, Array<Object>]*] *attribute_paths
    #   each attribute path is a symbol or array of symbols
    # @return [Array<Object, Array<Object>>] array of attribute paths permitted
    def select_permitted *attribute_paths
      attribute_paths.select { |attribute_path| permitted?(attribute_path) }
    end

    # Rejects the attribute paths which are permitted. Opposite of select_permitted.
    # Returns the attribute paths which are not permitted.
    #
    # @param [Array] prefix_path
    #   namespace in which each of the given attribute paths are in
    # @param [[Object, Array<Object>]*] *attribute_paths
    #   each attribute path is an object(string) or array
    # @return [Array<Object, Array<Object>>] array of attribute paths remaining
    def reject_permitted *attribute_paths
      attribute_paths.reject { |attribute_path| permitted?(attribute_path) }
    end

    # Permits some attribute paths
    #
    # @param [Array] prefix_path
    #   path to prepend to each attribute path
    # @param [[Object, Array]*] *attribute_paths
    def permit *attribute_paths
      copy_on_write!
      # don't permit if already permitted
      reject_permitted(*attribute_paths).each do |attribute_path|
        permitted_paths << canonicalize(attribute_path) # prefix_path = [] because of copy on write
      end
      self
    end

#    # Merges the permissions from another Permissions object
#    #
#    # @param [Permissions] permissions
#    # @param [Array<Symbol>] prefix
#    #   prefix to prepend to paths in permissions
#    # @return self
#    def merge permissions, prefix = []
#      permitted_paths.merge permissions.permitted_paths.map{|path| prefix+path} if permissions.is_a? self.class
#      self
#    end

    protected

    def permitted_paths
      @permitted_paths ||= Set.new
    end

    private
    # Is this still referencing another objects permissions?
    def reference?
      !@prefix_path.nil?
    end

    # Make a copy if this still references something else, since we are planning on writing soon
    def copy_on_write!
      if prefix_path == []
        @permitted_paths = permitted_paths.dup
      elsif reference?
        @permitted_paths, old_set = Set.new, permitted_paths
        old_set.each do |path|
          @permitted_paths << path[prefix_path.size...path.size] if path[0...prefix_path.size] == prefix_path
        end
      end
      @prefix_path = nil
    end

    def path_tainted? attribute_path
      attribute_path.tainted? or attribute_path.any? { |element| element.tainted? }
    end

    # Caution: Will mutate path
    def permitted_by_wildcard? path
      unless path.empty?
        path[-1] = :*
        return true if permitted_paths.include? path
      end
      until path.empty?
        path[-1] = :**
        return true if permitted_paths.include? path
        path.pop
      end
      false
    end

    # Converts symbols to strings (except for wildcard symbol)
    def canonicalize array
      array = Array(array)
      canonical_array = array.map{|e|e.is_a?(Symbol) ? e.to_s : e}
      canonical_array[-1] = array.last if [:*, :**].include? array.last
      canonical_array.taint if array.tainted?
      canonical_array
    end

  end
end

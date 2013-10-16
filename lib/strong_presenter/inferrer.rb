module StrongPresenter
  # @private
  # Helper class for inferring class names
  class Inferrer
    attr_accessor :input, :suffix

    # Constructs inferer object
    # @param [String] input
    #   Input name as base to infer from
    # @param [String] suffix
    #   Suffix which must be present in input to remove
    def initialize(input, suffix = "")
      self.input = input
      self.suffix = suffix
    end

    # Extracts name by removing suffix
    # @return [String]
    def extract_name
      raise UnextractableError if input.nil? || input.demodulize !~ /.+#{suffix}$/
      input.chomp(suffix)
    end

    # Retrieve inferred class if it exists. If not, nil is returned.
    # @yield (optional) for further transforming name
    # @yieldparam [String] name after suffix removed
    # @yieldreturn [String] name after transformation
    # @return [Class] inferred class
    def inferred_class
      name = extract_name
      name = yield name if block_given?
      name.constantize
    rescue NameError => error
      raise unless Inferrer.missing_name?(error, name)
      nil
    end

    protected
    # Detect if error is due to inferred class not existing, or some other error
    def self.missing_name?(error, name)
      return true if error.is_a? UnextractableError
      missing_name = error.missing_name
      length = [missing_name.length, name.length].min
      missing_name[-length..0] == name[-length..0]
    end
    class UnextractableError < NameError; end
  end
end

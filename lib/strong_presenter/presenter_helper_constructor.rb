module StrongPresenter
  # @private
  # Defines helper methods in controllers to access instance variables as presenters
  class PresenterHelperConstructor
    # settings: controller to define in, presenter factory, block to execute, options for valid actions
    def initialize(controller_class, block, options)
      @controller_class = controller_class
      @factory = StrongPresenter::Factory.new(options.slice!(:only, :except))
      @block = block
      @action_matcher = setup_action_matcher(options)
    end

    # Returns proc to check if action matches
    def setup_action_matcher(options)
      options.each { |k,v| options[k] = Array(v).map(&:to_sym) unless v.nil? }
      ->(action) { (options[:only].nil? || options[:only].include?(action)) && (options[:except].nil? || !options[:except].include?(action)) }
    end

    # call to construct helper
    def call(variable)
      @object = "@#{variable}"
      @presenter = "@#{variable}_presenter"
      construct(variable)
    end

    private
    attr_accessor :controller_class, :factory, :presenter, :block

    # actually construct the helper
    def construct(variable)
      shadowed_method = get_shadow_method(variable)
      action_matcher = @action_matcher
      memoized_presenter = method(:memoized_presenter).to_proc

      controller_class.send :define_method, variable do |*args|
        return shadowed_method.call self, *args unless action_matcher.call(action_name.to_sym) # scoped by controller action?
        raise ArgumentError.new("wrong number of arguments (#{args.size} for 0)") unless args.empty?
        memoized_presenter.call(self)
      end
    end

    # method which will be shadowed by the defined helper
    def get_shadow_method(method_name) # alias_method_chain without name pollution
      shadowed_method = controller_class.send :instance_method, method_name if controller_class.send :method_defined?, method_name
      return lambda { |obj, *args| raise NoMethodError } if shadowed_method.nil?
      return lambda { |obj, *args| shadowed_method.bind(obj).call(*args) }
    end

    # get presenter, memoized
    def memoized_presenter(controller)
      return controller.send(:instance_variable_get, presenter) if controller.send(:instance_variable_defined?, presenter)
      controller.send(:instance_variable_set, presenter, wrapped_object(controller))
    end

    # wrap model with presenter and return
    def wrapped_object(controller)
      factory.wrap(controller.send :instance_variable_get, @object) { |presenter| self.instance_exec presenter, &block }
    end
  end
end

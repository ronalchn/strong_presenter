module StrongPresenter
  # @private
  class PresenterAssociation

    def initialize(association, options, &block)
      options.assert_valid_keys(:with, :scope)

      @association = association

      @scope = options.delete(:scope)
      @block = block

      @factory = StrongPresenter::Factory.new(options)
    end

    def wrap(parent)
      associated = parent.send(:object).send(association)
      associated = associated.send(scope) if scope

      @wrapped = factory.wrap(associated) do |presenter|
        parent.instance_exec presenter, &@block if @block
      end
    end

    private
    attr_reader :factory, :association, :scope

  end
end

module StrongPresenter
  module Labelable
    extend ActiveSupport::Concern

    module ClassMethods
      # Pass a hash to set attribute labels { attribute => label }
      # Pass an array to retrieve labels for field symbols. If no label is set, the return
      # value is the humanized field by default.
      #
      def labels fields = nil
        @labels ||= {}
        if fields.nil?
          return @labels
        elsif fields.class == Hash
          @labels.merge!(fields)
        else
          labels = Array(fields).map { |field| @labels[field] || field.to_s.humanize }
          return labels if fields.respond_to? :map
          labels.first
        end
      end
    end

    # returns hash of attribute labels if no argument given
    # if list of attributes given, returns array of labels for permitted attributes
    # in this case, a block can be accepted to take |label, attribute|
    #
    def labels *fields
      presenter_class = self.class
      return presenter_class.labels if fields.empty?
      fields = select_permitted(fields)
      presenter_class.labels(fields).tap do |labels|
        labels.zip(fields).each do |label, field|
          yield label, field if block_given?
        end
      end
    end

  end
end

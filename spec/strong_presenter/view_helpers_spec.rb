require 'spec_helper'
require 'support/shared_examples/view_helpers'

module StrongPresenter
  describe ViewHelpers do
    it_behaves_like "view helpers", Class.new{include ViewHelpers}.new
  end
end

module StrongPresenter
  class Permissions < Set
    module All
    end
    def self.all
      @permit_all ||= Set.new [StrongPresenter::Permissions::All]
    end

    def complete?
      self.include? StrongPresenter::Permissions::All
    end

    def permit_all!
      self.clear
      self << StrongPresenter::Permissions::All
    end
  end
end

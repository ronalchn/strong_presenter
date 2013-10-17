require 'active_record'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/schema.rb'

class Wheel < ActiveRecord::Base
  belongs_to :vehicle, polymorphic: true
end

class Car < ActiveRecord::Base
  has_many :wheels, as: :vehicle
end


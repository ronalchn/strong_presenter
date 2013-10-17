ActiveRecord::Schema.define do
  self.verbose = false

  create_table :cars, :force => true do |t|
    t.string :license_plate
    t.timestamps
  end
  create_table :wheels, :force => true do |t|
    t.references :vehicle, polymorphic: true
    t.timestamps
  end
end

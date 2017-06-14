class CreateDonations < ActiveRecord::Migration[5.0]
  def change
    create_table :donations do |t|
    	t.string :source
    	t.boolean :completed, :default => false
    	t.belongs_to :dropoff_location, index:true

      t.timestamps
    end
  end
end

class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :userid
      t.string :passwordhash

      t.timestamps
    end
  end
end

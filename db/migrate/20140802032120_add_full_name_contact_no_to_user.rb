class AddFullNameContactNoToUser < ActiveRecord::Migration
  def change
    add_column :users, :fullname, :string
    add_column :users, :contactno, :string
  end
end
class CreateHumanTissues < ActiveRecord::Migration
  def self.up
    create_table :human_tissues do |t|
      t.string :slug
      t.string :name
      t.string :description
    end
    add_index :human_tissues, :slug, :unique => true
  end

  def self.down
    remove_index :human_tissues, :slug
    drop_table :human_tissues
  end
end

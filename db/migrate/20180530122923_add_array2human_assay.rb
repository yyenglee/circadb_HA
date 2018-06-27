class AddArray2humanAssay < ActiveRecord::Migration
  def self.up
    add_column :human_tissues, :gene_chip_id, :integer
    add_index :human_tissues, :gene_chip_id
  end

  def self.down
    remove_index :human_tissues, :gene_chip_id
    remove_column :human_tissues, :gene_chip_id
  end
end

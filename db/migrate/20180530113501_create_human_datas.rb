class CreateHumanDatas < ActiveRecord::Migration
  def self.up
    create_table :human_datas do |t|
      t.integer :human_tissue_id
      t.integer :probeset_id
      t.string :human_tissue_name
      t.string :probeset_name
      t.string :time_points, :limit => 2000
      t.string :data_points, :limit => 2000
      t.references :human_tissue
      t.references :probeset
    end
    add_index :human_datas, :probeset_id
    add_index :human_datas, :probeset_name
    add_index :human_datas, :human_tissue_name
    add_index :human_datas, :human_tissue_id
  end

  def self.down
    remove_index :human_datas, :probeset_id
    remove_index :human_datas, :human_tissue_id
    remove_index :human_datas, :human_tissue_name
    remove_index :human_datas, :probeset_name
    drop_table :human_datas
  end
end

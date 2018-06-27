class CreateHumanStats < ActiveRecord::Migration
  def self.up
    create_table :human_stats do |t|
      t.integer :human_tissue_id
      t.integer :human_data_id
      t.integer :probeset_id
      t.string :human_tissue_name
      t.string :probeset_name
      t.float :cyclop_fitmean
      t.float :cyclop_amplitude
      t.float :cyclop_phase
      t.float :cyclop_p_value
      t.float :cyclop_FDR_value
      t.float :cyclop_rsqr
      t.float :cyclop_rAMP
      t.references :human_data
    end
    add_index :human_stats, :probeset_name
    add_index :human_stats, :human_tissue_name
    add_index :human_stats, :human_tissue_id
    add_index :human_stats, :probeset_id
    add_index :human_stats, :human_data_id
    add_index :human_stats, :cyclop_FDR_value
    add_index :human_stats, :cyclop_p_value
    add_index :human_stats, :cyclop_rsqr
    add_index :human_stats, :cyclop_rAMP
  end

  def self.down
    remove_index :human_stats, :human_data_id
    remove_index :human_stats, :human_tissue_id
    remove_index :human_stats, :probeset_id
    remove_index :human_stats, :probeset_name
    remove_index :human_stats, :human_tissue_name
    remove_index :human_stats, :cyclop_FDR_value
    remove_index :human_stats, :cyclop_p_value
    remove_index :human_stats, :cyclop_rsqr
    remove_index :human_stats, :cyclop_rAMP
    drop_table :human_stats
  end
end

class HumanStat < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 5
  cattr_reader :pval_filters
  @@pval_filters = []
  #["jtk", "JTK", "cosopt", "Lomb Scargle", "fisherg", "DeLichtenberg" ].each_slice(2) do |id,txt|
  ["jtk", "JTK"].each_slice(2) do |id,txt|
    @@pval_filters += [["#{txt} P-value","#{id}_p_value"],
    #                   ["#{txt} Q-value","#{id}_q_value"] ]
                       ["FDR","#{id}_q_value"] ]
  end

  belongs_to :human_assay
  belongs_to :probeset
  belongs_to :human_data

  # full text index using sphinx
  define_index do
    %w{probeset_name
      transcript_id
      representative_public_id
      unigene_id
      gene_symbol
      gene_title
      entrez_gene
      swissprot
      refseq_protein_id
      refseq_transcript_id
      target_description}.map do |m|
        eval <<-EOF
        indexes probeset.#{m}, :as => :#{m}
        EOF
    end
  #  # define filter attributes
    has assay_id, cyclop_p_value, cyclop_FDR_value, cyclop_phase, cyclop_rsqr, cyclop_rAMP
  #end
end


# == Schema Information
#
# Table name: probeset_stats
#
#  id                    :integer(4)      not null, primary key
#  assay_id              :integer(4)
#  probeset_id           :integer(4)
#  probeset_data_id      :integer(4)
#  assay_name            :string(255)
#  probeset_name         :string(255)
#  cyclop_p_value        :float
#  cyclop_FDR_value      :float
#  cyclop_phase          :float
#  cyclop_rsqr           :float
#  cyclop_rAMP           :float
#

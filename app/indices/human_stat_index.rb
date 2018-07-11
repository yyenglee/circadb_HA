ThinkingSphinx::Index.define :probeset_stat, :with => :active_record do
  indexes probeset.probeset_name, :as => :probeset_name
  indexes probeset.transcript_id, :as => :transcript_id
  indexes probeset.representative_public_id, :as => :representative_public_id
  indexes probeset.unigene_id, :as => :unigene_id
  indexes probeset.gene_symbol, :as => :gene_symbol
  indexes probeset.gene_title, :as => :gene_title
  indexes probeset.entrez_gene, :as => :entrez_gene
  indexes probeset.swissprot, :as => :swissprot
  indexes probeset.refseq_protein_id, :as => :refseq_protein_id
  indexes probeset.refseq_transcript_id, :as => :refseq_transcript_id
  indexes probeset.target_description, :as => :target_description

  has human_tissue_id, cyclop_p_value, cyclop_FDR_value, cyclop_phase, cyclop_rsqr, cyclop_rAMP

end

class Probeset < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 25
  belongs_to :gene_chip
  has_many :probeset_stats
  has_many :probeset_datas
  

  ## URL helpers
  # unigene_urls
  def unigene_url
    return '<i>None</i>' if (unigene_id == '---' || unigene_id.nil?)
    template = '<a href="http://www.ncbi.nlm.nih.gov/UniGene/clust.cgi?ORG=%s&CID=%s">%s</a>'
    org, uid = unigene_id.split('.')
    return sprintf(template,org,uid,unigene_id)
  end

  def gene_symbol_url
    return '<i>None</i>' if entrez_gene == '---' || entrez_gene.nil?
    # grabs the entrez_gene for the ID and gene-symbol for the link text
    template = "<a href='http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&cmd=Retrieve&list_uids=%d&dopt=full_report'>%s</a>"
    links = []
    e = entrez_gene.split(/\s+\/\/\/\s+/)
    g = gene_symbol.split(/\s+\/\/\/\s+/)
    e.each_index do |i|
      links <<  sprintf(template,e[i],g[i])
    end
    return links.join(" &nbsp; ")
  end
  
  def refseq_transcript_url
    # could be multiple
    return '<i>None</i>' if refseq_transcript_id == '---' || refseq_transcript_id.nil?
    template = "<a href='http://www.ncbi.nlm.nih.gov/coreutils/dispatch.cgi?db=36&term=ACC'>ACC</a>"
    links = []
    refseq_transcript_id.split(/\s+\/\/\/\s+/).each do |a|
      links <<  template.gsub('ACC',a)
    end
    return links.join(" &nbsp; ")
  end

  def refseq_protein_url
    return '<i>None</i>' if refseq_protein_id == '---' || refseq_protein_id.nil?
    # could be multiple 
    template = "<a href='http://www.ncbi.nlm.nih.gov/coreutils/dispatch.cgi?db=1&term=ACC'>ACC</a>"
    links = []
    refseq_transcript_id.split(/\s+\/\/\/\s+/).each do |a|
      links <<  template.gsub('ACC',a)
    end
    return links.join(" &nbsp; ")
  end
end


# == Schema Information
#
# Table name: probesets
#
#  id                            :integer(4)      not null, primary key
#  gene_chip_id                  :integer(4)
#  probeset_name                 :string(255)
#  genechip_name                 :string(255)
#  species                       :string(255)
#  annotation_date               :string(255)
#  sequence_type                 :string(255)
#  sequence_source               :string(255)
#  transcript_id                 :string(255)
#  target_description            :text
#  representative_public_id      :string(255)
#  archival_unigene_cluster      :string(255)
#  unigene_id                    :string(255)
#  genome_version                :string(255)
#  alignments                    :text
#  gene_title                    :text
#  gene_symbol                   :string(255)
#  chromosomal_location          :string(255)
#  unigene_cluster_type          :string(255)
#  ensembl                       :string(255)
#  entrez_gene                   :string(255)
#  swissprot                     :string(255)
#  ec                            :string(255)
#  omim                          :string(255)
#  refseq_protein_id             :string(255)
#  refseq_transcript_id          :string(255)
#  flybase                       :string(255)
#  agi                           :string(255)
#  wormbase                      :string(255)
#  mgi_name                      :string(255)
#  rgd_name                      :string(255)
#  sgd_accession_number          :string(255)
#  go_biological_process         :text
#  go_cellular_component         :text
#  go_molecular_function         :text
#  pathway                       :string(255)
#  interpro                      :string(255)
#  trans_membrane                :text
#  qtl                           :string(255)
#  annotation_description        :text
#  annotation_transcript_cluster :text
#  transcript_assignments        :string(255)
#  annotation_notes              :text
#

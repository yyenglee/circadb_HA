desc "Seed database using raw data"
namespace :seed_GTExAnno do
  require "ar-extensions"
  require "csv"

  task :genechips_GTEx => :environment do
    c = ActiveRecord::Base.connection
    g = GeneChip.new(:slug => "Human_GTEx", :name => "Human RNAseq GTEx V7")
    g.save
  end

  desc "Seed GTEx human annotations"
  task :GTEx_human_probesets => :environment do
    # probes
    #fields = %w{ gene_chip_id probeset_name genechip_name species annotation_date sequence_type sequence_source
    #  unigene_id genome_version gene_title gene_symbol ensembl entrez_gene swissprot ec omim refseq_protein_id refseq_transcript_id flybase agi wormbase mgi_name rgd_name sgd_accession_number go_biological_process go_cellular_component go_molecular_function pathway interpro trans_membrane qtl annotation_description annotation_transcript_cluster transcript_assignments annotation_notes }
    fields = %w{ gene_chip_id probeset_name genechip_name species annotation_date sequence_type sequence_source gene_symbol ensembl entrez_gene }

    g  = GeneChip.find(:first, :conditions => ["slug like ?","Human_GTEx"])
    count = 0
    buffer = []
    puts "=== Begin human GTEx Probeset insert ==="
    CSV.foreach("/home/My/linux/HogeneschLab/redo/process_cyclop_data/GTExv7CircAtlas_EntrezIDs_anno.csv", :headers=> true ) do |ps|
      count += 1
      if count>1
        geneID, ens_id, entrez_id = ps[0], ps[1], ps[2]
        buffer << [g.id, geneID, "Human_GTEx", "Homo Sapiens","2018-06-21","RNA-seq", "GTEx", geneID, ens_id, entrez_id]
        #buffer << [g.id] + ps.values_at
        if count % 1000 == 0
          Probeset.import(fields,buffer)
          buffer = []
          puts count
        end
      end
    end
    Probeset.import(fields,buffer)
    puts count
    puts "=== End GTEx human Probeset insert ==="
  end

  desc "Loads all seed data into the DB"
  task :all => [:genechips_GTEx, :GTEx_human_probesets] do
  end

end

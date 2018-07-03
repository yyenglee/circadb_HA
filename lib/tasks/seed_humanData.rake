desc "Seed database using raw data"
namespace :seedGTExExample do
  require "ar-extensions"
  require "csv"

  desc "Seed human assays"
  task :assays => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from human_tissues"

    a = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    #a = GeneChip.find(:first, :conditions => ["slug like ?","Human_GTEx"])
    g = HumanTissue.new(:slug => "Aorta", :name => "Aorta(GTEx.V7)", :description => "Aorta_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Artery_Coronary", :name => "Artery Coronary(GTEx.V7)", :description => "ArteryCoronary_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Artery_Tibial", :name => "Artery Tibial(GTEx.V7)", :description => "ArteryTibial_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Colon", :name => "Colon(GTEx.V7)", :description => "Colon_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Esophagus", :name => "Esophagus(GTEx.V7)", :description => "Esophagus_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Fat_SQ", :name => "Fat SQ(GTEx.V7)", :description => "FatSQ_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Fat_Visceral", :name => "Fat Visceral(GTEx.V7)", :description => "FatVisceral_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Heart_Atrial", :name => "Heart Atrial(GTEx.V7)", :description => "HeartAtrial_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Liver", :name => "Liver(GTEx.V7)", :description => "Liver_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Lung", :name => "Lung(GTEx.V7)", :description => "Lung_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Nerve_Tibial", :name => "Nerve Tibial(GTEx.V7)", :description => "NerveTibial_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Pituitary", :name => "Pituitary(GTEx.V7)", :description => "Pituitary_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    g = HumanTissue.new(:slug => "Thyroid", :name => "Thyroid(GTEx.V7)", :description => "Thyroid_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save

    puts "=== Test human tissue data inserted ==="
  end

  task :datas => :environment do
    ## OK start the imports

    puts "=== GTEx Raw Data insert starting ==="
    fields = %w{ human_tissue_id human_tissue_name probeset_id probeset_name time_points data_points}

    # Match gene symbol and id from annotation file
    g = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    #g = GeneChip.find(:first, :conditions => ["slug like ?","Human_GTEx"])
    probesets = {}
    g.probesets.each do |p|
      if !p.gene_symbol.nil?
        probesets[p.gene_symbol] = p.id
      end
    end

    # Match tissue type and id
    sampleID = {}
    HumanTissue.all.each do |etype|
      sampleID[etype.slug] = etype.id
    end

    puts "=== Raw Data insert starting ==="
    count = 0
    buffer = []
    File.open("#{RAILS_ROOT}/raw_data/PhasevsTMPInfo.txt","r").each do |line|
      count += 1
      if count > 1
        line = line.gsub('"','')
        line = line.split(" ")

        tissue = line[2]
        time_points = line[3].split(",")
        data_points = line[4].split(",")

        info = []
        time_points.each_with_index do |time, index|
          info.push([time,data_points[index]])
        end

        info = info.sort_by{|time,data| time}
        time_points = info.map{|time,data| time.to_f}
        data_points = info.map{|time,data| data.to_f}

        gene_symbol = line[1].gsub('"','')
        psid = probesets[gene_symbol]
        #if !psid.blank?
        #  buffer << [a.id(), a.slug, psid, gene_symbol, time_points.to_json, data_points.to_json]
        #end
        buffer << [sampleID[tissue], tissue, psid, gene_symbol, time_points.to_json, data_points.to_json]
      end

      if count % 1000 == 0
        HumanData.import(fields,buffer)
        puts count
        buffer = []
      end
    end
    HumanData.import(fields,buffer)
    puts "=== Raw Data insert ended (count= #{count}) ==="
  end

  task :stats => :environment do
    puts "=== Stat Data insert starting ==="
    fields = %w{ human_tissue_id human_tissue_name human_data_id probeset_id probeset_name cyclop_phase cyclop_p_value cyclop_FDR_value cyclop_rsqr cyclop_rAMP cyclop_fitmean cyclop_amplitude}

    g = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    probesets = {}
    g.probesets.each do |p|
      if !p.gene_symbol.nil?
        probesets[p.gene_symbol] = p.id
      end
    end

    count = 0
    buffer = []
    humandata = {}
    cur_tissue = ""
    tissueID = nil

    CSV.foreach("#{RAILS_ROOT}/raw_data/GTExv7CircAtlas_CoReg_withEntrezIDs.csv") do |row|
      count += 1
      if count > 1 && row[3] != "NA"  #skip first line for header, skip if no hgnc_symbol available
        psname = row[0]
        tissue = row[4].gsub(" ","_")

        if cur_tissue != tissue   # reset humandata info if tissue name changed
          cur_tissue = tissue
          t = HumanTissue.find(:first, :conditions => ["slug = ?", tissue])
          tissueID = t.id
          humandata = {}
          t.human_datas.each do |d|
            if !d.probeset_name.nil?
              humandata[d.probeset_name] = d.id
            end
          end
        end

        psid = probesets[psname]
        hdid = humandata[psname]
        buffer << [tissueID, tissue, hdid, psid, psname] + row[5...12].to_a
        if count % 1000 == 0
          HumanStat.import(fields,buffer)
          buffer = []
          puts count
        end
      end
    end

    HumanStat.import(fields,buffer)
    puts "=== Stat Data end (count = #{count}) END ==="

  end

  desc "Backfills in references for FKs to probeset_stats to probeset_datas."
  task :refbackfill =>  :environment do
    puts "=== Back filling FK probeset_stats.probset_data_id  ==="
    c = ActiveRecord::Base.connection
    c.execute "update probeset_stats s set s.probeset_data_id = (select d.id from probeset_datas d where d.probeset_id = s.probeset_id and d.assay_id = s.assay_id limit 1)"
  end

  desc "Loads all seed data into the DB"
  task :all => [:human_tissues, :human_tissues, :datas, :stats] do
  end

  task :delete_from_data => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from probeset_datas"
    c.execute "delete from human_datas"
  end

  task :delete_from_probesets => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from probesets"
    puts "=== delete_from_probesets done!"
  end

  task :delete_from_stats => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from probeset_stats"
    c.execute "delete from human_stats"
  end

  task :delete_from_humanstats => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from human_stats"
  end

  task :delete_from_human => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from human_tissues"
    c.execute "delete from human_datas"
    c.execute "delete from human_stats"
  end

  desc "Warning: Deletes all content"
  task :delete_from_all => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from gene_chips"
    c.execute "delete from assays"
    c.execute "delete from human_tissues"
    c.execute "delete from probesets"
    c.execute "delete from probeset_stats"
    c.execute "delete from probeset_datas"
    c.execute "delete from human_datas"
    c.execute "delete from human_stats"
    puts "=== delete_from_all done!"
  end

  desc "Build the sphinx index"
  task :build_sphinx => ["ts:stop", "ts:config", "ts:rebuild", "ts:start"]

  desc "Fill database from scratch"
  #task :fill => [:delete_from_all, :genechips,
  #  :mouse430_probesets, :u74av1_probesets, :gnf1m_probesets, :hugene_probesets,
  #  :mogene_probesets, :assays, :datas, :human_tissues, :stats, :refbackfill, :build_sphinx]
  task :fill => [:delete_from_human, :assays, :datas, :stats]
  #task :fill => [:stats]

  desc "Reset human stats"
  task :reset_humanStat => [:delete_from_humanstats, :stats]

  desc "Refill Probesets"
  task :refill_probesets => [:delete_from_probesets, :mouse430_probesets,
    :u74av1_probesets, :gnf1m_probesets, :hugene_probesets, :mogene_probesets,
    :build_sphinx]

  desc "Reset the source data"
  task :reset_data => [:delete_from_data, :assays, :human_tissues, :datas, :refbackfill,
    :build_sphinx] do
  end

  desc "Reset the source stats"
  task :reset_stats => [:delete_from_stats,  :stats, :refbackfill,
    :build_sphinx] do
  end

  desc "Reset assays and genechips"
  task :reset_assays => [:assays, :human_tissues, :genechips, :refbackfill,
    :build_sphinx] do
  end



end

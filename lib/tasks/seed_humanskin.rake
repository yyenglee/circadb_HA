desc "Seed database using raw data"
namespace :seedPnGSkin do
  require "ar-extensions"
  require "csv"

  desc "Seed human assays"
  task :assays => :environment do
    c = ActiveRecord::Base.connection
    #c.execute "delete from human_tissues"
    a = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    #a = GeneChip.find(:first, :conditions => ["slug like ?","Human_GTEx"])
    g = HumanTissue.new(:slug => "PnG_arm_epidermis", :name => "P&G Arm Epidermis", :description => "P&G arm epidermis", :gene_chip_id => a.id)
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
    File.open("#{RAILS_ROOT}/raw_data/PnG_PhasevsTMPInfo.txt","r").each do |line|
      count += 1
      if count > 1
        line = line.gsub('"','')
        line = line.split(" ")

        tissue = line[1]
        time_points = line[2]
        data_points = line[3]
        #time_points = line[2].split(",")
        #data_points = line[3].split(",")

        #info = []
        #time_points.each_with_index do |time, index|
        #  info.push([time,data_points[index]])
        #end

        #info = info.sort_by{|time,data| time}
        #time_points = info.map{|time,data| time.to_f}
        #data_points = info.map{|time,data| data.to_f}

        gene_symbol = line[0].gsub('"','')
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

    CSV.foreach("#{RAILS_ROOT}/raw_data/PnG_Arm_Epidermis_Cosinor.csv") do |row|
      count += 1
      if count > 1 #skip first line for header, skip if no hgnc_symbol available
        psname = row[0]
        tissue = "PnG_arm_epidermis"

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
        phase = (row[5].to_f + 2*Math::PI) % (2*Math::PI)
        pval = row[3]
        fdr = row[11]
        rsqr = row[9]
        ramp = row[12]
        fitmean = row[7]
        amp = row[6]

        buffer << [tissueID, tissue, hdid, psid, psname, phase, pval, fdr, rsqr, ramp, fitmean, amp]
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
  task :all => [:assays, :datas, :stats] do
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

  desc "Build the sphinx index"
  task :build_sphinx => ["ts:stop", "ts:config", "ts:rebuild", "ts:start"]

  desc "Fill database from scratch"
  #task :fill => [:delete_from_all, :genechips,
  #  :mouse430_probesets, :u74av1_probesets, :gnf1m_probesets, :hugene_probesets,
  #  :mogene_probesets, :assays, :datas, :human_tissues, :stats, :refbackfill, :build_sphinx]
  task :fill => [:assays, :datas, :stats]
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

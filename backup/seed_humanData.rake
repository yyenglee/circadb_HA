desc "Seed database using raw data"
namespace :seedGTExExample do
  require "ar-extensions"
  require "csv"

  desc "Seed human assays"
  task :assays => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from human_assays"

    g  = HumanAssay.new(:slug => "Artery_Tibial", :name => "ArteryTibial_V7FILTER_Random160SamplesMAXJakeoGram", :description => "ArteryTibial_V7FILTER_Random160SamplesMAXJakeoGram")
    g.save

    puts "=== Test human assay data inserted ==="

  end

  task :datas => :environment do
    ## OK start the imports
    puts "=== GTEx Raw Data insert starting ==="
    # fields = %w{ assay_id assay_name probeset_name time_points data_points chart_url_base }
    fields = %w{ assay_id assay_name probeset_id probeset_name time_points data_points chart_url_base }

    # Insert example data to table
    g  = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    probesets = {}
    g.probesets.each do |p|
      probesets[p.gene_symbol]= p.id
    end

    %w{ "Artery_Tibial" }.each do |etype|
      count = 0
      buffer = []
      a = HumanAssay.find(:first, :conditions => ["slug = ?", etype])
      puts "=== Raw Data #{etype} insert starting ==="

      #File.open("#{RAILS_ROOT}/seed_data/hughes_#{etype}_data","r" ).each do |line|
      File.open("/home/My/linux/HogeneschLab/redo/process_cyclop_data/example_input.txt","r").each do |line|
        count += 1
        line = line.split(" ")
        time_points = line[3].split(",").map {|element| element}
        data_points = line[4].split(",").map {|element| element}
        #cubase = line[3]
        cubase = "unknown"
        psid = probesets[line[2]]
        buffer << [a.id(), a.slug, psid, line[2], time_points.to_json, data_points.to_json,cubase]

        if count % 1000 == 0
          HumanData.import(fields,buffer)
          puts count
          buffer = []
        end
      end
      HumanData.import(fields,buffer)
      puts "=== Raw Data #{etype} end (count= #{count}) ==="
    end
    puts "=== Raw Data insert ended ==="
  end

  task :stats => :environment do
    puts "=== Stat Data insert starting ==="

    fields = %w{  assay_id assay_name probeset_id probeset_data_id probeset_name cyclop_p_value cyclop_FDR_value cyclop_phase cyclop_rsqr cyclop_rAMP}
    g  = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    probesets = {}

    g.probesets.each do |p|
      p.probeset_name
      probesets[p.probeset_name]= p.id
    end

    %w{ Artery Tibial }.each do |etype|
      #liver
      count = 0
      buffer = []
      a = HumanAssay.find(:first, :conditions => ["slug = ?", etype])
      puts "=== Stat Data #{etype} start ==="

      #CSV.foreach("#{RAILS_ROOT}/seed_data/hughes_#{etype}_stats") do |row|
      CSV.foreach("/home/My/linux/HogeneschLab/redo/process_cyclop_data/example_input_cyclopStat.csv") do |row|
        count += 1
        aslug, psname = 0,row[0].to_i
        psid = probesets[row[0]]
        #buffer << [a.id, a.slug,psid, psid, psname] + row[1..-1].to_a
        buffer << [a.id, a.slug, psid, psid, psname] + row[6..9].to_a
        if count % 1000 == 0
          HumanStat.import(fields,buffer)
          buffer = []
          puts count
        end
      end
      HumanStat.import(fields,buffer)
      puts "=== Stat Data #{etype} end (count = #{count}) ==="
    end

    puts "=== Stat Data END ==="
  end


  desc "Backfills in references for FKs to probeset_stats to probeset_datas."
  task :refbackfill =>  :environment do
    puts "=== Back filling FK probeset_stats.probset_data_id  ==="
    c = ActiveRecord::Base.connection
    c.execute "update probeset_stats s set s.probeset_data_id = (select d.id from probeset_datas d where d.probeset_id = s.probeset_id and d.assay_id = s.assay_id limit 1)"
  end

  desc "Loads all seed data into the DB"
  task :all => [:human_assays, :human_assays, :datas, :stats] do
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

  desc "Warning: Deletes all content"
  task :delete_from_all => :environment do
    c = ActiveRecord::Base.connection
    c.execute "delete from gene_chips"
    c.execute "delete from assays"
    c.execute "delete from human_assays"
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
  #  :mogene_probesets, :assays, :datas, :human_assays, :stats, :refbackfill, :build_sphinx]
  task :fill => [:assays, :datas, :stats]

  desc "Refill Probesets"
  task :refill_probesets => [:delete_from_probesets, :mouse430_probesets,
    :u74av1_probesets, :gnf1m_probesets, :hugene_probesets, :mogene_probesets,
    :build_sphinx]

  desc "Reset the source data"
  task :reset_data => [:delete_from_data, :assays, :human_assays, :datas, :refbackfill,
    :build_sphinx] do
  end

  desc "Reset the source stats"
  task :reset_stats => [:delete_from_stats,  :stats, :refbackfill,
    :build_sphinx] do
  end

  desc "Reset assays and genechips"
  task :reset_assays => [:assays, :human_assays, :genechips, :refbackfill,
    :build_sphinx] do
  end



end

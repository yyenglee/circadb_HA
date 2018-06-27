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
    g = HumanTissue.new(:slug => "Artery_Tibial", :name => "Artery Tibial", :description => "ArteryTibial_V7FILTER_Random160SamplesMAXJakeoGram", :gene_chip_id => a.id)
    g.save
    puts "=== Test human tissue data inserted ==="
  end

  task :datas => :environment do
    ## OK start the imports
    puts "=== GTEx Raw Data insert starting ==="
    fields = %w{ human_tissue_id human_tissue_name probeset_id probeset_name time_points data_points}

    # Insert example data to table
    g = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    #g = GeneChip.find(:first, :conditions => ["slug like ?","Human_GTEx"])
    probesets = {}
    g.probesets.each do |p|
      if !p.gene_symbol.nil?
        probesets[p.gene_symbol] = p.id
      end
    end

    %w{ Artery_Tibial }.each do |etype|
      count = 0
      buffer = []
      a = HumanTissue.find(:first, :conditions => ["slug = ?", etype])
      puts "=== Raw Data #{etype} insert starting ==="

      #File.open("#{RAILS_ROOT}/seed_data/hughes_#{etype}_data","r" ).each do |line|
      File.open("/home/My/linux/HogeneschLab/redo/process_cyclop_data/example_input_2digit.txt","r").each do |line|
        count += 1
        if count > 1
          line = line.gsub('"','')
          line = line.split(" ")
          #time_points = line[2].split(",").map {|element| element}
          #data_points = line[3].split(",").map {|element| element}

          time_points = line[2].split(",")
          data_points = line[3].split(",")

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
          buffer << [a.id(), a.slug, psid, gene_symbol, time_points.to_json, data_points.to_json]
        end

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
    fields = %w{ human_tissue_id human_tissue_name human_data_id probeset_id probeset_name cyclop_phase cyclop_p_value cyclop_FDR_value cyclop_rsqr cyclop_rAMP cyclop_fitmean cyclop_amplitude}

    g = GeneChip.find(:first, :conditions => ["slug like ?","HuGene1_0"])
    #g = GeneChip.find(:first, :conditions => ["slug like ?","Human_GTEx"])
    probesets = {}
    g.probesets.each do |p|
      if !p.gene_symbol.nil?
        probesets[p.gene_symbol] = p.id
      end
    end

    %w{ Artery_Tibial }.each do |etype|
      count = 0
      buffer = []
      a = HumanTissue.find(:first, :conditions => ["slug = ?", etype])
      humandata = {}
      a.human_datas.each do |i|
        if !i.probeset_name.nil?
          humandata[i.probeset_name] = i.id
        end
      end

      #CSV.foreach("#{RAILS_ROOT}/seed_data/hughes_#{etype}_stats") do |row|
      CSV.foreach("/home/My/linux/HogeneschLab/redo/process_cyclop_data/example_input_cyclopStat.csv") do |row|
        count += 1
        if count > 1 && row[3] != "NA"  #skip first line for header, skip if no hgnc_symbol available
          aslug, psname = 0,row[0]
          psid = probesets[row[0]]
          hdid = humandata[row[0]]

          #buffer << [a.id, a.slug,psid, psid, psname] + row[1..-1].to_a
          #if !psid.blank?
          #  buffer << [a.id(), a.slug, hdid, psid, row[0]] + row[5...12].to_a
          #end
          buffer << [a.id(), a.slug, hdid, psid, row[0]] + row[5...12].to_a
          if count % 1000 == 0
            HumanStat.import(fields,buffer)
            buffer = []
            puts count
          end
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
  task :fill => [:assays, :datas, :stats]
  #task :fill => [:stats]

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

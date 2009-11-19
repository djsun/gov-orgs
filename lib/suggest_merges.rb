require File.expand_path('utility', File.dirname(__FILE__))
require File.expand_path('validator', File.dirname(__FILE__))

require 'rubygems'
require 'fastercsv'
require 'highline'

class MergeSuggester

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end

  SIM_FILE = expand('../data/similarities_sorted.csv')
  ORG_FILE = expand('../data/orgs.yaml')

  def run
    read_similarities
    read_organizations
    make_suggestions
    write_organizations
  end

  def read_similarities
    puts 'Reading similarity file...'
    @similarites = FasterCSV.read(SIM_FILE)
    raise unless @similarites
    puts '%i rows imported.' % [@similarites.length]
  end

  def read_organizations
    puts "\nReading organizations file..."
    @data = {}
    @uids = []
    File.open(ORG_FILE) do |f|
      YAML.load_documents(f) do |org|
        @uids << org['uid']
        @data[org['uid']] = org['versions']
      end
    end
  end

  def write_organizations
    puts "\nWriting organizations file..."
    File.open(ORG_FILE, "w") do |f|
      @uids.each do |uid|
        YAML.dump(YAML::Omap['uid', uid, 'versions', @data[uid]], f)
      end
    end
  end

  def make_suggestions
    catch(:quit) do
      @similarites.each do |row|
        uid_1, uid_2, sim = row[0], row[1], row[2].to_f
        puts "\n============================================================"
        if already_merged?(uid_1, uid_2)
          puts "\n  One of the following has already been merged:"
          puts "  * #{uid_1}"
          puts "  * #{uid_2}"
          next
        end
        puts "\n  Similarity: %.5f" % [sim]
        display_names(uid_1, uid_2)
        loop do
          puts "\n  Press a key : [m]erge | [M]erge & save | [s]kip | [q]uit ..."
          case HighLine::SystemExtensions.get_character.chr
          when 'm'
            do_merge(uid_1, uid_2)
            break
          when 'M'
            do_merge(uid_1, uid_2)
            write_organizations
            break
          when 's'
            puts "\n  Skipping merge"
            break
          when 'q'
            throw :quit
          end
        end
      end
    end
  end

  def already_merged?(*items)
    items.any? { |uid| @data[uid][0]['merged_into'] }
  end

  def do_merge(uid_1, uid_2)
    puts "\n  Merging"
    data_1 = @data[uid_1][0]['data']
    data_2 = @data[uid_2][0]['data']
    
    @data[uid_1].insert(0, YAML::Omap[
      'data',        data_1.merge(data_2),
      'time',        Utility.time_format(Time.new),
      'who',         File.basename(__FILE__),
      'merged_from', uid_2,
    ])

    @data[uid_2].insert(0, YAML::Omap[
      'deleted',     true,
      'merged_into', uid_1,
      'time',        Utility.time_format(Time.new),
      'who',         File.basename(__FILE__),
    ])
  end

  def display_names(*items)
    items.each_with_index do |uid, k|
      puts "\n  (%i) %s" % [k + 1, uid]
      puts @data[uid].to_yaml.split("\n").map { |x| "      #{x}" }.join("\n")
    end
  end

end

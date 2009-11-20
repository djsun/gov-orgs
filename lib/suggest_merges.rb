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
  TAILED_FILES = [
    expand('../data/temp_merge_1.txt'),
    expand('../data/temp_merge_2.txt'),
  ]
  MERGE_LOG        = expand('../data/merge_log.yaml')
  NO_MERGE_LOG     = expand('../data/no_merge_log.yaml')
  UNSURE_MERGE_LOG = expand('../data/unsure_merge_log.yaml')

  def run
    @merge = read_log(MERGE_LOG)
    @no_merge = read_log(NO_MERGE_LOG)
    @unsure_merge = read_log(UNSURE_MERGE_LOG)
    setup_tailed_files
    read_similarities
    read_organizations
    open_merge_logs
    make_suggestions
    close_tailed_files
    close_merge_logs
  end
  
  def read_log(filename)
    items = {}
    return unless File.exists?(filename)
    File.open(filename) do |f|
      YAML.load_documents(f) do |item|
        items[item['uids']] = true
      end
    end
    items
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
  
  def setup_tailed_files
    @tailed_files = TAILED_FILES.map { |fname| File.open(fname, 'a') }
    puts "\nPlease open up two terminal windows and run these commands:"
    TAILED_FILES.each { |fname| puts "tail -f #{fname}" }
    puts "\nPress any key to continue..."
    HighLine::SystemExtensions.get_character
  end
  
  def close_tailed_files
    @tailed_files.each { |f| f.close }
  end

  def open_merge_logs
    @merge_log        = File.open(MERGE_LOG, 'a')
    @no_merge_log     = File.open(NO_MERGE_LOG, 'a')
    @unsure_merge_log = File.open(UNSURE_MERGE_LOG, 'a')
  end

  def close_merge_logs
    @merge_log.close
    @no_merge_log.close
    @unsure_merge_log.close
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
        
        if marked?([uid_1, uid_2])
          puts "\n  The user has marked these:"
          puts "  * #{uid_1}"
          puts "  * #{uid_2}"
          next
        end
        
        puts "\n  Similarity: %.5f" % [sim]
        display_names(uid_1, uid_2)
        loop do
          puts "\n  [=] same | [/] different | [u] unsure | [q]uit"
          case HighLine::SystemExtensions.get_character.chr
          when '='
            log(:merge, uid_1, uid_2)
            break
          when '/'
            log(:no_merge, uid_1, uid_2)
            break
          when 'u'
            log(:unsure, uid_1, uid_2)
            break
          when 'q'
            throw :quit
          end
        end
      end
    end
  end
  
  def marked?(uids)
    raise ArgumentError unless uids.length == 2
    marked_same?(uids) || marked_different?(uids) || marked_unsure?(uids)
  end
  
  def marked_same?(uids)
    raise ArgumentError unless uids.length == 2
    [uids, uids.reverse].any? { |x| @merge[x] }
  end
  
  def marked_different?(uids)
    raise ArgumentError unless uids.length == 2
    [uids, uids.reverse].any? { |x| @no_merge[x] }
  end
  
  def marked_unsure?(uids)
    raise ArgumentError unless uids.length == 2
    [uids, uids.reverse].any? { |x| @unsure_merge[x] }
  end

  def already_merged?(*items)
    items.any? { |uid| @data[uid][0]['merged_into'] }
  end
  
  def log(command, uid_1, uid_2)
    log = case command
    when :merge    then @merge_log
    when :no_merge then @no_merge_log
    when :unsure   then @unsure_merge_log
    else raise "unexpected"
    end
    puts "  Log: #{command}"
    YAML.dump(YAML::Omap[
      'uids', [uid_1, uid_2],
      'time', Utility.time_format(Time.now),
    ], log)
    log.flush
  end

  def display_names(*items)
    items.each_with_index do |uid, k|
      f = @tailed_files[k]
      clear(f)
      f.puts "\n  (%i) %s" % [k + 1, uid]
      f.puts @data[uid].to_yaml.split("\n").map { |x| "      #{x}" }.join("\n")
      f.flush
    end
  end
  
  def clear(stream)
    stream.print "\e[H\e[2J"
  end

end

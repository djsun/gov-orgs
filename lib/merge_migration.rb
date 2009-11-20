require File.expand_path('utility', File.dirname(__FILE__))
require File.expand_path('validator', File.dirname(__FILE__))

class MergeMigration

  class Error < RuntimeError; end
  class ValidationError < Error; end

  FIELDS = %w(
    orgs_filename
    merge_log_filename
  )
  
  FIELDS.each { |f| attr_accessor f.intern }

  def initialize(options)
    FIELDS.each do |f|
      self.send(:"#{f}=", options[f.intern])
    end
  end
  
  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  TEMP_FILENAME = expand('../data/orgs_temp.yaml')
  
  def run
    validate
    read_merge_file
    read_organizations
    process_merges
    write_organizations
  end
    
  protected

  def read_merge_file
    puts "\nReading #{merge_log_filename}..."
    @merges = []
    File.open(merge_log_filename) do |f|
      YAML.load_documents(f) do |item|
        @merges << { 
          :uids => item['uids'],
          :time => item['time'],
        }
      end
    end
  end

  def read_organizations
    puts "\nReading organizations file..."
    @versions = {}
    @uids = []
    File.open(orgs_filename) do |f|
      YAML.load_documents(f) do |org|
        @uids << org['uid']
        @versions[org['uid']] = org['versions']
      end
    end
  end

  def process_merges
    @merges.each do |item|
      merge_uids(item[:uids])
    end
  end

  def merge_uids(uids)
    raise ArgumentError unless uids.length == 2
    puts "\nLooking: #{uids[0]} and #{uids[1]}"
    leaf_uids = uids.map do |uid|
      leaf_uid = lookup_leaf_uid(uid)
      if uid != leaf_uid
        puts "  #{uid} already merged into #{leaf_uid}"
      end
      leaf_uid
    end
    merge_leaf_uids(leaf_uids)
  end
  
  def lookup_leaf_uid(start_uid)
    uid = start_uid
    loop do
      merged_into = @versions[uid][0]['merged_into']
      if merged_into
        uid = merged_into
      else
        break
      end
    end
    uid
  end
  
  def merge_leaf_uids(uids)
    raise ArgumentError unless uids.length == 2
    uids.each do |uid|
      raise "#{uid} must be a leaf" if @versions[uid][0]['merged_into']
    end
    if uids[0] == uids[1]
      puts "  Skipping merge; uids are identical: #{uids[0]}"
      return
    end

    puts "Merging: #{uids[0]} and #{uids[1]}"
    datas = uids.map { |uid| @versions[uid][0]['data'] }
    @versions[uids[0]].insert(0, YAML::Omap[
      'data',        datas[0].merge(datas[1]),
      'time',        Utility.time_format(Time.new),
      'who',         File.basename(__FILE__),
      'merged_from', uids[1],
    ])
    @versions[uids[1]].insert(0, YAML::Omap[
      'deleted',     true,
      'merged_into', uids[0],
      'time',        Utility.time_format(Time.new),
      'who',         File.basename(__FILE__),
    ])
  end

  def write_organizations
    puts "\nWriting organizations file..."
    File.open(orgs_filename, "w") do |f|
      @uids.each do |uid|
        YAML.dump(YAML::Omap[
          'uid', uid,
          'versions', @versions[uid]
        ], f)
      end
    end
  end
  
  def validate
    FIELDS.each do |f|
      raise ValidationError, "Missing #{f}" unless send(:"#{f}")
    end
  end
  
end

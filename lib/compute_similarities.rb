require 'rubygems'
require File.expand_path('search', File.dirname(__FILE__))

class SimilarityComputer

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  IN_FILE         = expand('../data/orgs.yaml')
  SIMILARITY_FILE = expand('../data/similarities.csv')

  THRESHOLD = 0.5

  def run(verbose=false)
    setup
    tokenize
    compare_orgs
    teardown
  end

  def setup
    @data = load_orgs
    puts 'Loaded %s entities.' % @data.length
    @similarity_file = File.open(SIMILARITY_FILE, 'w')
    raise "Could not open file" unless @similarity_file
  end
  
  def load_orgs
    data = {}
    File.open(IN_FILE) do |f|
      YAML.load_documents(f) do |org|
        latest_version = org['versions'][0]
        if latest_version['deleted'] != true
          uid = org['uid']
          data[uid] = latest_version
        end
      end
    end
    data
  end

  def tokenize
    @data.each do |uid, latest_version|
      names = latest_version['data']['names']
      latest_version['_keywords'] = Search.process(names)
    end
  end
  
  def compare_orgs
    uids = @data.keys
    length = @data.length
    (0 ... length).each do |i1|
      print "."
      STDOUT.flush if i1 % 25 == 0
      uid_1 = uids[i1]
      k1 = @data[uid_1]['_keywords']
      ((i1 + 1) ... length).each do |i2|
        uid_2 = uids[i2]
        k2 = @data[uid_2]['_keywords']
        sim = (k1 & k2).length.to_f / (k1 | k2).length
        if sim >= THRESHOLD
          @similarity_file.puts('%s,%s,%0.5f' % [uid_1, uid_2, sim])
        end
      end
    end
    puts ""
  end

  def teardown
    @similarity_file.close
  end
  
end

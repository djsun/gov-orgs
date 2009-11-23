require File.expand_path('../lib/utility', File.dirname(__FILE__))
require File.expand_path('../lib/validator', File.dirname(__FILE__))

class MarkAsDifferentMigration

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  IN_FILE = expand('../data/orgs.yaml')
  NO_MERGE_LOG = expand('../data/no_merge_log.yaml')

  def run
    setup
    uids = matching_uids(/.* State(,)? County(,)? (and|or) City Websites/)
    append_to_no_merge_log(uids)
    @no_merge_log.close
  end

  def setup
    @no_merge_log = File.open(NO_MERGE_LOG, 'a')
    @data = load_orgs
    puts 'Loaded %s entities.' % @data.length
  end
  
  def matching_uids(regex)
    uids = []
    @data.each do |uid, latest_version|
      names = latest_version['data']['names']
      if names.any? { |x| x =~ regex }
        uids << uid
      end
    end
    uids
  end
  
  def append_to_no_merge_log(uids)
    length = uids.length
    (0 ... length).each do |i1|
      print "."
      STDOUT.flush if i1 % 25 == 0
      uid_1 = uids[i1]
      ((i1 + 1) ... length).each do |i2|
        uid_2 = uids[i2]
        log(@no_merge_log, uid_1, uid_2)
      end
    end
    puts ""
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
  
  def log(log, uid_1, uid_2)
    YAML.dump(YAML::Omap[
      'uids', [uid_1, uid_2],
      'time', Utility.time_format(Time.now),
    ], log)
    log.flush
  end

end

MarkAsDifferentMigration.new.run

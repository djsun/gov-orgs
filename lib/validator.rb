require 'yaml'

class Validator
  
  class Error < RuntimeError; end
  
  FIELDS = %w(filename)

  FIELDS.each { |f| attr_accessor f.intern }

  def initialize(options)
    FIELDS.each do |f|
      self.send(:"#{f}=", options[f.intern])
    end
  end

  def run
    validate
    puts "\nValidating #{filename}..."
    File.open(filename) do |f|
      org_count     = 0
      version_count = 0
      deleted_count = 0
      active_count  = 0
      uids = {}
      puts "Loading #{filename}..."
      YAML.load_documents(f) do |org|
        org_count += 1
        version_count += org['versions'].length
        uids = check_uid(org, uids)
        latest_version = org['versions'][0]
        if latest_version['deleted'] == true
          deleted_count += 1
        else
          active_count += 1
        end
      end
      puts '  * %5i entities' % [org_count]
      puts '  * %5i active entities' % [active_count]
      puts '  * %5i deleted entities' % [deleted_count]
      puts '  * %5i versions' % [version_count]
    end
  end
  
  protected
  
  def check_uid(org, uids)
    uid = org['uid']
    if uids[uid]
      raise "Non Unique UID : #{uid}"
    else
      uids[uid] = true
    end
    uids
  end

  def validate
    FIELDS.each do |f|
      raise Error, "Missing #{f}" unless send(:"#{f}")
    end
  end

end

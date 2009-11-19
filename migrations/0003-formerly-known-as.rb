require File.expand_path('../lib/utility', File.dirname(__FILE__))
require File.expand_path('../lib/validator', File.dirname(__FILE__))

class FormerlyKnownAsExtractor

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  MASTER_FILE = expand('../data/orgs.yaml')
  TEMP_FILE   = expand('../data/orgs_temp.yaml')

  def run
    modify_each_org do |org|
      data = org['versions'][0]['data'].deep_clone
      process_names(data)
      new_version = YAML::Omap[
        'data', data,
        'time', Utility.time_format(Time.now),
        'who',  File.basename(__FILE__),
      ]
      org['versions'].insert(0, new_version)
    end
  end
  
  protected

  def modify_each_org
    i = 0
    puts "Reading #{MASTER_FILE}..."
    File.open(MASTER_FILE) do |f_in|
      puts "Creating #{TEMP_FILE}..."
      File.open(TEMP_FILE, 'w') do |f_out|
        YAML.load_documents(f_in) do |org|
          print "."
          STDOUT.flush if i % 25 == 0
          i += 1
          if org['versions'][0]['deleted'] != true
            yield(org)
          end
          YAML.dump(org, f_out)
        end
      end
    end
    puts ""
    puts "Deleting #{MASTER_FILE}..."
    unless File.delete(MASTER_FILE) == 1
      raise Error
    end
    puts "Renaming #{TEMP_FILE} to #{MASTER_FILE}..."
    File.rename(TEMP_FILE, MASTER_FILE)
  end

  def process_names(data)
    cleaned_names = []
    former_names  = []
    data['names'].each do |name|
      cleaned_name, former_name = process_name(name)
      cleaned_names << cleaned_name
      former_names  << former_name
    end
    data['names']        = cleaned_names.uniq
    data['former_names'] = former_names.uniq
  end
  
  def process_name(name) 
    name =~ /(.*) \(formerly (the )?(.*)\)/
    cleaned_name = Regexp.last_match(1)
    former_name  = Regexp.last_match(3)
    if cleaned_name
      [cleaned_name, former_name]
    else
      [name, nil]
    end
  end

end

FormerlyKnownAsExtractor.new.run

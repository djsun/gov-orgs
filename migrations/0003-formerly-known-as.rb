require File.expand_path('../lib/utility', File.dirname(__FILE__))
require File.expand_path('../lib/validator', File.dirname(__FILE__))

class FormerlyKnownAsExtractor

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  MASTER_FILE = expand('../data/orgs.yaml')
  TEMP_FILE   = expand('../data/orgs_temp.yaml')

  def run
    Utility.modify_each_org(MASTER_FILE, TEMP_FILE) do |org|
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

  def process_names(data)
    cleaned_names = []
    former_names  = []
    data['names'].each do |name|
      cleaned_name, former_name = process_name(name)
      cleaned_names << cleaned_name
      former_names  << former_name if former_name
    end
    data['names'] = cleaned_names.uniq
    unless former_names.empty?
      data['former_names'] = former_names.uniq
    end
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

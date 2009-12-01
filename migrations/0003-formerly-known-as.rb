require File.expand_path('../lib/utility', File.dirname(__FILE__))
require File.expand_path('../lib/validator', File.dirname(__FILE__))

class FormerlyKnownAsExtractor

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  MASTER_FILE    = expand('../data/orgs.yaml')
  TEMP_FILE      = expand('../data/orgs_temp.yaml')
  REPOSITORY_URL = 'http://github.com/djsun/gov-orgs'

  def run
    Utility.modify_each_org(MASTER_FILE, TEMP_FILE) do |org|
      data = org['versions'][0]['data'].deep_clone
      new_data = process_names(data)
      if new_data != data
        new_version = YAML::Omap[
          'data', new_data,
          'time', Utility.time_format(Time.now),
          'by',   YAML::Omap[
            'repository', REPOSITORY_URL,
            'file',       File.basename(__FILE__),
          ],
        ]
        org['versions'].insert(0, new_version)
      end
    end
  end
  
  protected

  def process_names(data)
    new_data = data.clone
    cleaned_names = []
    former_names  = []
    data['names'].each do |name|
      cleaned_name, former_name = process_name(name)
      cleaned_names << cleaned_name
      former_names  << former_name if former_name
    end
    new_data['names'] = cleaned_names.uniq
    unless former_names.empty?
      new_data['former_names'] = former_names.uniq
    end
    new_data
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

require File.expand_path('../lib/utility', File.dirname(__FILE__))
require File.expand_path('../lib/validator', File.dirname(__FILE__))

class ParetheticalExtractor

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
    cleaned_names  = []
    parentheticals = []
    new_data['names'].each do |name|
      c, p = process_name(name)
      cleaned_names << c
      parentheticals.concat(p)
    end
    data['names'] = cleaned_names.uniq
    unless parentheticals.empty?
      new_data['parentheticals'] = parentheticals.uniq
    end
    new_data
  end
  
  def process_name(name)
    s = name.dup
    parentheticals = []
    loop do
      s =~ /(.*) \((.*)\)/
      cleaned = Regexp.last_match(1)
      parenthetical = Regexp.last_match(2)
      if cleaned
        parentheticals << parenthetical
        s = cleaned
      else
        break
      end
    end
    [s, parentheticals]
  end

end

ParetheticalExtractor.new.run

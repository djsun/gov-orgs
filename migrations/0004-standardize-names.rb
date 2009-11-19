require File.expand_path('../lib/utility', File.dirname(__FILE__))
require File.expand_path('../lib/validator', File.dirname(__FILE__))

class NameStandardizer

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  MASTER_FILE = expand('../data/orgs.yaml')
  TEMP_FILE   = expand('../data/orgs_temp.yaml')

  def run
    File.open(MASTER_FILE) do |f_in|
      File.open(TEMP_FILE, 'w') do |f_out|
        YAML.load_documents(f_in) do |org|
          latest_version = org['versions'][0]
          if latest_version['deleted'] != true
            data = latest_version['data'].deep_clone
            names = data['names']
            s_names = standardize_names(names)
            data['standardized_names'] = s_names
            data['names'] = (s_names + names).uniq
            new_version = YAML::Omap[
              'data', data,
              'time', Utility.time_format(Time.now),
              'who',  File.basename(__FILE__),
            ]
            org['versions'].insert(0, new_version)
          end
          YAML.dump(org, f_out)
        end
      end
    end
    unless File.delete(MASTER_FILE) == 1
      raise Error
    end
    File.rename(TEMP_FILE, MASTER_FILE)
  end
  
  protected
  
  def standardize_names(names)
    names.map { |name| standardize(name) }.uniq
  end

  def simplify(name)
    name.
      gsub(/generally, no additional specification available/i, '').
      gsub(/- except .*/i, '').
      gsub(/, except .*/i, '').
      gsub(/\(except .*/i, '').
      gsub(/  /, ' ').strip.
      gsub(/,$/, '').strip
  end
  
  STANDARDIZATION_PATTERNS = [
    [/\bAdmin\.\b/     , 'Administration'    ],
    [/\bAssist\.\b/    , 'Assistant'         ],
    [/\bImmed\.\b/     , 'Immediate'         ],
    [/\bIntergov\.\b/  , 'Intergovernmental' ],
    [/\bInternat'l\b/  , 'International'     ],
    [/\bNat'l\b/       , 'National'          ],
    [/\bSec'y\b/       , 'Secretary'         ],
    [/\bSec\.\b/       , 'Secretary'         ],
    [/&/               , ' and '             ],
    [/\//              , ' / '               ],
    [/  /              , ' '                 ],
  ]

  def standardize(name)
    name = simplify(name.dup)
    STANDARDIZATION_PATTERNS.each do |x|
      name.gsub!(x[0], x[1])
    end
    name.strip
  end
  
end

standardizer = NameStandardizer.new
standardizer.run

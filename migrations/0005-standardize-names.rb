require File.expand_path('../lib/utility', File.dirname(__FILE__))

class NameStandardizer

  def self.expand(s)
    File.expand_path(s, File.dirname(__FILE__))
  end
  
  MASTER_FILE = expand('../data/orgs.yaml')
  TEMP_FILE   = expand('../data/orgs_temp.yaml')

  def run
    Utility.modify_each_org(MASTER_FILE, TEMP_FILE) do |org|
      data = org['versions'][0]['data'].deep_clone
      names = data['names']
      simplified_names = simplify_names(names)
      standardized_names = standardize_names(simplified_names)
      new_names = (standardized_names + simplified_names).uniq
      if new_names != names
        data['names'] = new_names
        new_version = YAML::Omap[
          'data', data,
          'time', Utility.time_format(Time.now),
          'who',  File.basename(__FILE__),
        ]
        org['versions'].insert(0, new_version)
      end
    end
  end
  
  protected
  
  def simplify_names(names)
    names.map { |s| simplify(s) }.uniq
  end
  
  def standardize_names(names)
    names.map { |s| standardize(s) }.uniq
  end

  def simplify(name)
    name.
    gsub(/generally, .*/i, '').
    gsub(/- except .*/i, '').
    gsub(/, except .*/i, '').
    gsub(/\(except .*/i, '').
    gsub(/\//, ' / ').
    gsub(/  /, ' ').
    strip.
    gsub(/,$/, '').
    strip
  end
  
  STANDARDIZATION_PATTERNS = [
    [/Admin\./          , 'Administration'          ],
    [/Assist\./         , 'Assistant'               ],
    [/Cntr/             , 'Center'                  ],
    [/Commun\./         , 'Communications'          ],
    [/Comm\.-In-Chief/  , 'Commander-In-Chief'      ],
    [/Dep\. Comm\./     , 'Deputy Commissioner'     ],
    [/Develop\./        , 'Development'             ],
    [/Econ\./           , 'Economic'                ],
    [/Ed\./             , 'Education'               ],
    [/Enviro\./         , 'Environmental'           ],
    [/Equip\./          , 'Equipment'               ],
    [/Immed\./          , 'Immediate'               ],
    [/Info\./           , 'Information'             ],
    [/Intergov\./       , 'Intergovernmental'       ],
    [/Internat'l/       , 'International'           ],
    [/Mgmt\./           , 'Management'              ],
    [/Nat'l/            , 'National'                ],
    [/Preserv\./        , 'Preservation'            ],
    [/Rehab\. Services/ , 'Rehabilitation Services' ],
    [/Scholar\./        , 'Scholarship'             ],
    [/Sec'y/            , 'Secretary'               ],
    [/Sec\./            , 'Secretary'               ],
    [/Spec\. Ed/        , 'Special Ed'              ],
    [/Tank-Auto\./      , 'Tank-Automotive'         ],
    [/&/                , ' and '                   ],
    [/  /               , ' '                       ],
  ]

  def standardize(name)
    name = name.dup
    STANDARDIZATION_PATTERNS.each do |x|
      name.gsub!(x[0], x[1])
    end
    name.strip
  end
  
end

standardizer = NameStandardizer.new
standardizer.run

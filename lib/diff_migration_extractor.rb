require File.expand_path('migrations', File.dirname(__FILE__))
require File.expand_path('utility', File.dirname(__FILE__))

class DiffMigrationExtractor

  class Error < RuntimeError; end

  FIELDS = %w(
    new_filename
    old_filename
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
    
  TEMPLATE_FILENAME = expand('../templates/diff_migration_template.rb')

  def run
    validate
    versions_new = org_versions_by_uid(new_filename)
    versions_old = org_versions_by_uid(old_filename)
    changes = []
    versions_new.each do |uid, versions|
      if versions != versions_old[uid]
        changes << YAML::Omap[
          'uid', uid,
          'new_version', versions[0]
        ]
      end
    end
    data_filename = Migrations.next_filename('extracted', 'yaml')
    Utility.write_yaml(data_filename, changes)
    migration_filename = Migrations.next_filename('extracted')
    FileUtils.copy(TEMPLATE_FILENAME, migration_filename)
  end
  
  protected
  
  def org_versions_by_uid(filename)
    orgs = {}
    File.open(filename) do |f|
      YAML.load_documents(f) do |org|
        orgs[org['uid']] = org['versions']
      end
    end
    orgs
  end
  
  def validate
    FIELDS.each do |f|
      raise Error, "Missing #{f}" unless send(:"#{f}")
    end
  end

end

require File.expand_path('../lib/diff_migration', File.dirname(__FILE__))

def expand(path)
  File.expand_path(path, File.dirname(__FILE__))
end

DiffMigration.new({
  :orgs_filename => expand('../data/orgs.yaml'),
  :diff_filename => expand(File.basename((__FILE__), '.*') + '.yaml'),
}).run

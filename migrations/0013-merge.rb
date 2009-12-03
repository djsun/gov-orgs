require File.expand_path('../lib/merge_migration', File.dirname(__FILE__))

def expand(path)
  File.expand_path(path, File.dirname(__FILE__))
end

MergeMigration.new({
  :orgs_filename      => expand('../data/orgs.yaml'),
  :merge_log_filename => expand(File.basename((__FILE__), '.*') + '.yaml'),
}).run

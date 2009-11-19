desc "backup orgs.yaml"
task :backup do
  require 'lib/backup'
  BackerUpper.new({
    :input_filename => 'data/orgs.yaml',
    :output_filename => 'data/orgs_backup.yaml',
  }).run
end

desc "validate orgs.yaml"
task :validate do
  require 'lib/validator'
  Validator.new({
    :filename => 'data/orgs.yaml',
  }).run
end

namespace :migration do
  desc "create new migration"
  task :new do
    require 'lib/migrations'
    FileUtils.copy('templates/new_migration_template.rb',
      Migrations.next_filename('change_this'))
  end

  desc "create new migration from orgs.yaml"
  task :extract do
    require 'lib/migration_extractor'
    MigrationExtractor.new({
      :new_filename => 'data/orgs.yaml',
      :old_filename => 'data/orgs_backup.yaml',
    }).run
  end
  
  desc "destroy orgs.yaml and run all migrations"
  task :run_all do
    require 'lib/migrations'
    Migrations.run_all
  end
end

namespace :similarities do
  task :compute do
    require 'lib/compute_similarities'
    SimilarityComputer.new.run
  end
  
  task :sort do
    require 'lib/sort_similarities'
    SimilaritySorter.new.run
  end
end


namespace :merge do
  desc "calculate similarities"
  task :setup => ["similarities:compute", "similarities:sort"]
  
  desc "start interactive merge"
  task :interactive do
    require 'lib/suggest_merges'
    MergeSuggester.new.run
  end
end

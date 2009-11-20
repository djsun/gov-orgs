desc "backup orgs.yaml"
task :backup do
  require 'lib/backup'
  BackerUpper.new({
    :input_filename  => 'data/orgs.yaml',
    :output_filename => 'data/orgs_backup.yaml',
  }).run
end

desc "copy orgs.yaml to orgs_baseline.yaml"
task :baseline do
  require 'lib/backup'
  BackerUpper.new({
    :input_filename  => 'data/orgs.yaml',
    :output_filename => 'data/orgs_baseline.yaml',
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
  namespace :create do
    desc "create new plain migration"
    task :plain do
      require 'lib/migrations'
      FileUtils.copy('templates/new_migration_template.rb',
        Migrations.next_filename('change_this'))
    end
    
    desc "create migration from merge_log.yaml"
    task :merge do
      require 'lib/merge_migration_extractor'
      MergeMigrationExtractor.new({
        :merge_log_filename => 'data/merge_log.yaml'
      }).run
    end

    desc "create migration from diff of orgs.yaml and orgs_baseline.yaml"
    task :diff do
      require 'lib/diff_migration_extractor'
      DiffMigrationExtractor.new({
        :new_filename => 'data/orgs.yaml',
        :old_filename => 'data/orgs_baseline.yaml',
      }).run
    end
  end
  
  namespace :run do
    desc "destroy orgs.yaml and run all migrations"
    task :all do
      require 'lib/migrations'
      Migrations.run_all
    end
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

desc "interactive merge"
task :merge => ["similarities:compute", "similarities:sort"] do
  require 'lib/suggest_merges'
  MergeSuggester.new.run
end

task :_merge do
  require 'lib/suggest_merges'
  MergeSuggester.new.run
end

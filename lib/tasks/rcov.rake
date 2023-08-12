# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  require "rspec/core/rake_task"

  namespace :rcov do
    RSpec::Core::RakeTask.new(:rspec_run) do |t|
      Rake::Task["db:test:prepare"].invoke
      t.pattern = "spec/**/*_spec.rb"
      t.rcov = true
      t.rcov_opts = %w{--rails --exclude osx\/objc,gems\/,spec\/,controllers\/,helpers\/}
    end
    desc "Run both specs and features to generate aggregated coverage"
    task :all do |t|
      rm "coverage.data" if File.exist?("coverage.data")
      Rake::Task["rcov:rspec_run"].invoke
    end
    desc "Run only rspecs"
    task :rspec do |t|
      rm "coverage.data" if File.exist?("coverage.data")
      Rake::Task["rcov:rspec_run"].invoke
    end
  end
end

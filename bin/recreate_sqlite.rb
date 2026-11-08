#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "optparse"
require "rbconfig"
require "sqlite3"
require "date"

APP_ROOT = File.expand_path("..", __dir__)

options = { environment: ENV.fetch("RAILS_ENV", "development") }
OptionParser.new do |parser|
  parser.banner = "Usage: bin/recreate_sqlite.rb [options]"
  parser.on("-e", "--environment ENV", "Rails environment (default: development)") do |environment|
    options[:environment] = environment
  end
  parser.on("-d", "--database PATH", "SQLite database to recreate") do |path|
    options[:database] = path
  end
  parser.on(
    "--advisement-authorization-start-date DATE",
    "Default for missing start_date (default: 2013-06-01)"
  ) do |date|
    options[:advisement_authorization_start_date] = Date.iso8601(date).to_s
  rescue ArgumentError
    raise OptionParser::InvalidArgument, "expected date in YYYY-MM-DD format"
  end
end.parse!

environment = options[:environment]
advisement_authorization_start_date =
  options.fetch(:advisement_authorization_start_date, "2013-06-01")
rails = File.join(APP_ROOT, "bin", "rails")
ruby = RbConfig.ruby

database_path = options[:database] || IO.popen(
  { "RAILS_ENV" => environment, "DATABASE_URL" => ENV["DATABASE_URL"] }.compact,
  [ruby, rails, "runner", "puts ActiveRecord::Base.connection_db_config.database"],
  &:read
).strip
abort "Rails did not provide a SQLite database path" if database_path.empty?

database_path = File.expand_path(database_path, APP_ROOT)
abort "Database does not exist: #{database_path}" unless File.file?(database_path)

quote_identifier = ->(identifier) { "\"#{identifier.to_s.gsub("\"", "\"\"")}\"" }
metadata_tables = %w[ar_internal_metadata schema_migrations]
temporary_path = "#{database_path}.recreate-#{Process.pid}"
backup_path = "#{database_path}.backup-#{Time.now.strftime("%Y%m%d%H%M%S")}-#{Process.pid}"

source = SQLite3::Database.new(database_path)
prepared = false

begin
  FileUtils.rm_f(temporary_path)

  rails_status = system(
    { "RAILS_ENV" => environment, "DATABASE_URL" => "sqlite3:#{temporary_path}" },
    ruby,
    rails,
    "db:schema:load"
  )
  abort "Rails could not load db/schema.rb into #{temporary_path}" unless rails_status

  target = SQLite3::Database.new(temporary_path)
  source_tables = source.execute(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"
  ).flatten.reject { |name| metadata_tables.include?(name) }
  target_tables = target.execute(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"
  ).flatten.reject { |name| metadata_tables.include?(name) }

  missing_tables = source_tables - target_tables
  abort "Tables not present in db/schema.rb: #{missing_tables.join(", ")}" unless missing_tables.empty?

  target.execute("PRAGMA foreign_keys = OFF")
  target.execute("BEGIN")

  source_tables.each do |table|
    source_columns = source.execute("PRAGMA table_info(#{quote_identifier.call(table)})").map { |column| column[1] }
    target_info = target.execute("PRAGMA table_info(#{quote_identifier.call(table)})")
    target_columns = target_info.map { |column| column[1] }
    missing_columns = source_columns - target_columns
    abort "Columns missing from #{table}: #{missing_columns.join(", ")}" unless missing_columns.empty?

    quoted_table = quote_identifier.call(table)
    target_only_columns = target_info.select { |column| !source_columns.include?(column[1]) }
    defaults = if table == "advisement_authorizations"
                 { "start_date" => advisement_authorization_start_date }
               else
                 {}
               end
    missing_required_columns = target_only_columns.select do |column|
      column[3] == 1 && column[4].nil? && !defaults.key?(column[1])
    end
    unless missing_required_columns.empty?
      names = missing_required_columns.map { |column| column[1] }.join(", ")
      abort "No default configured for required columns in #{table}: #{names}. Existing database was not changed."
    end

    insert_columns = source_columns + target_only_columns.filter_map do |column|
      column[1] if defaults.key?(column[1])
    end
    quoted_columns = insert_columns.map { |column| quote_identifier.call(column) }.join(", ")
    quoted_source_columns = source_columns.map { |column| quote_identifier.call(column) }.join(", ")
    target.execute("DELETE FROM #{quoted_table}")
    source.execute("SELECT #{quoted_source_columns} FROM #{quoted_table}").each do |row|
      row += target_only_columns.filter_map { |column| defaults[column[1]] }
      placeholders = (["?"] * row.length).join(", ")
      target.execute(
        "INSERT INTO #{quoted_table} (#{quoted_columns}) VALUES (#{placeholders})",
        row
      )
    end
  rescue SQLite3::ConstraintException => e
    abort "Could not preserve #{table}: #{e.message}. Existing database was not changed."
  end

  sqlite_sequence_exists = lambda do |database|
    database.get_first_value(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'sqlite_sequence'"
    )
  end
  if sqlite_sequence_exists.call(target) && sqlite_sequence_exists.call(source)
    target.execute("DELETE FROM sqlite_sequence")
    source.execute("SELECT name, seq FROM sqlite_sequence").each do |name, sequence|
      next unless target_tables.include?(name)

      target.execute("INSERT INTO sqlite_sequence (name, seq) VALUES (?, ?)", [name, sequence])
    end
  end

  target.execute("COMMIT")
  target.execute("PRAGMA foreign_keys = ON")
  integrity = target.get_first_value("PRAGMA integrity_check")
  abort "Integrity check failed: #{integrity}" unless integrity == "ok"
  prepared = true
ensure
  target&.close
  source.close
  FileUtils.rm_f(temporary_path) unless prepared
end

FileUtils.cp(database_path, backup_path)
begin
  FileUtils.mv(temporary_path, database_path)
rescue StandardError
  FileUtils.rm_f(temporary_path)
  raise
end

puts "Recreated #{database_path} from db/schema.rb."
puts "Backup kept at #{backup_path}."

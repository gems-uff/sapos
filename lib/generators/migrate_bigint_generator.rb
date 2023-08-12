# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "active_support/inflector"


def columns_to_index(columns)
  if columns.count == 1
    return ":" + columns[0]
  end
  result = columns.collect { |x| ":" + x }.join(", ")
  "[#{result}]"
end

def create_code(result, wrap, foreign_keys, references_by_table, newtype, useoldname)
  wrap.each do |table, schema_tup|
    result << "    remove_index :#{table}, name: \"#{schema_tup[2]}\" if index_exists?(:#{table}, name: \"#{schema_tup[2]}\")"
  end
  foreign_keys.each do |fk, col1, col2, extra|
    sing1 = col1.singularize.capitalize
    sing2 = col2.singularize
    result << "    add_column :#{col1}, :temp_#{sing2}_id, #{newtype}"
    result << "    #{sing1}.update_all(\"temp_#{sing2}_id = #{sing2}_id\")"
    result << "    remove_reference :#{col1}, :#{sing2}"
  end
  result << ""

  references_by_table.each do |table, references|
    result << "    # #{table}"
    references.each do |reftable, fk_attr, columns, oldname|
      if useoldname
        result << "    remove_index :#{reftable}, name: \"#{oldname}\" if index_exists?(:#{reftable}, name: \"#{oldname}\")"
      else
        result << "    remove_index :#{reftable}, name: \"index_#{reftable}_on_#{columns.join("_and_")}\" if index_exists?(:#{reftable}, name: \"index_#{reftable}_on_#{columns.join("_and_")}\")"
      end
    end
    result << "    change_column :#{table}, :id, #{newtype}, unique: true, null: false, auto_increment: true"
    references.each do |reftable, fk_attr, columns, oldname|
      result << "    change_column :#{reftable}, :#{fk_attr}, #{newtype}"
      if useoldname
        result << "    add_index :#{reftable}, #{columns_to_index(columns)} unless index_exists?(:#{reftable}, #{columns_to_index(columns)})"
      else
        result << "    add_index :#{reftable}, #{columns_to_index(columns)}, name: \"#{oldname}\" unless index_exists?(:#{reftable}, #{columns_to_index(columns)})"
      end
    end
    result << ""
  end

  result << ""
  wrap.each do |table, schema_tup|
    result << "    change_column :#{table}, :#{schema_tup[0]}, #{newtype}"
    result << "    add_index :#{table}, #{columns_to_index(schema_tup[1])} unless index_exists?(:#{table}, #{columns_to_index(schema_tup[1])})"
  end
  foreign_keys.each do |fk, col1, col2, extra|
    extra = ", foreign_key: {#{extra.delete_prefix(",")} }" if extra
    sing1 = col1.singularize.capitalize
    sing2 = col2.singularize
    result << "    add_reference :#{col1}, :#{sing2}#{extra}"
    result << "    #{sing1}.update_all(\"#{sing2}_id = temp_#{sing2}_id\")"
    result << "    remove_column :#{col1}, :temp_#{sing2}_id"
  end
end


def create_migration(wrap, references_by_table, add_extra, foreign_keys)
  result = []
  result << "class MigrateIdsToBigint < ActiveRecord::Migration[6.0]"
  result << "  def up"
  create_code(result, wrap, foreign_keys, references_by_table, ":integer, limit: 8", true)
  result << ""
  result << "    # new indexes"
  add_extra.each do |table, fk_attr|
    result << "    add_index :#{table}, #{columns_to_index([fk_attr])} unless index_exists?(:#{table}, #{columns_to_index([fk_attr])})"
  end
  result << "  end"
  result << ""
  result << "  def down"
  result << "    # new indexes"
  add_extra.each do |table, fk_attr|
    result << "    remove_index :#{table}, name: \"index_#{table}_on_#{fk_attr}\" if index_exists?(:#{table}, name: \"index_#{table}_on_#{fk_attr}\")"
  end
  result << ""
  create_code(result, wrap, foreign_keys, references_by_table, ":integer", false)
  result << "  end"
  result << "end"
  result.join($/)
end

namespace :generate do
  task :create_bigint_migration do
    create_migration(wrap, references_by_table, add_extra, foreign_keys)
  end
end

class MigrateBigintGenerator < Rails::Generators::Base
  def create_bigint_migration
    models = {}

    Dir["app/models/*"].each do |name|
      model_name = name.match(/app\/models\/(.*?)\.rb/)[1].pluralize
      indexes = []
      data = File.read(name)
      data.scan(/belongs_to.*?:([\w_]*)(,.*)?/).collect do |match|
        name = match[0]
        table_name = name.pluralize
        fk_attr = name + "_id"
        if match[1]
          classname = match[1].match(/class_name: "(.*?)"/)
          table_name = classname[1].downcase.pluralize if classname
          fk = match[1].match(/foreign_key: "(.*?)"/)
          fk_attr = fk[1] if fk
        end
        indexes << [fk_attr, table_name, name]
      end
      models[model_name] = indexes
    end

    schema = File.read("db/schema.rb")
    tables = {}
    schema.scan(/  create_table "(.*?)".*? do \|t\|(.*?)end\n/m).collect do |match|
      indexes = []
      match[1].scan(/t.index \["(.*?)"\], name: "(.*?)"/).collect do |indexmatch|
        fk_attr = indexmatch[0]
        if indexmatch[0].count(",") > 0
          fk_attr = fk_attr.match(/([\w_]*?id)/)[0]
        end
        columns = indexmatch[0].split(/", "/)
        if fk_attr.end_with? "_id"
          indexes << [fk_attr, columns, indexmatch[1]]
        end
      end
      tables[match[0]] = indexes
    end

    foreign_keys = schema.scan(/(add_foreign_key "(.*?)", "(.*?)"(.*))/).collect(&:to_a)

    wrap = []
    add_extra = []

    references_by_table = Hash[tables.collect { |t, v| [ t, [] ] }]

    tables.each do |table, schema_indexes|
      if model_indexes = models[table]
        # Find relationships that existed in rails, but that did not exist in the database
        model_indexes.each do |fk_attr, table_name, belongs_to|
          unless schema_indexes.any? { |x| x[0] == fk_attr }
            add_extra << [table, fk_attr]
          end
        end
        schema_indexes.each do |schema_tup|
          found = false
          model_indexes.each do |model_tup|
            if model_tup[0] == schema_tup[0]
              found = true
              # build references using fk that exists in both
              references_by_table[model_tup[1]] << [table] + schema_tup
            end
          end
          unless found
            # fk that does not exist in rails
            wrap << [table, schema_tup]
          end
        end
      else
        # puts(key) # carrier_wave_files
      end
    end

    result = create_migration(wrap, references_by_table, add_extra, foreign_keys)
    create_file "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_migrate_ids_to_bigint.rb", result
  end
end

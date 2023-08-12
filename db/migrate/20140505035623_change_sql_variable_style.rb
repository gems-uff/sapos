# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeSqlVariableStyle < ActiveRecord::Migration[5.1]
  def up
    Query.transaction do
      Query.all.each do |query|
        query.update_attribute :sql, query.sql.gsub(/\%\{([^\}]+)\}/, ':\1')
      end
    end
  end

  def down
    Query.transaction do
      Query.all.each do |query|
        query.update_attribute :sql, query.sql.gsub(/:([a-zA-Z0-9_]+)/, '%{\1}')
      end
    end
  end
end

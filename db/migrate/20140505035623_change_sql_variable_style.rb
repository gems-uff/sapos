class ChangeSqlVariableStyle < ActiveRecord::Migration
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

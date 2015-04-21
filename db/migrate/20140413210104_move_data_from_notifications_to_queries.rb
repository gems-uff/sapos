# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class MoveDataFromNotificationsToQueries < ActiveRecord::Migration
  def up
    add_column :notifications, :query_id, :integer, :after => :id

    Notification.transaction do
      Notification.all.each do |notification|
        query = Query.new
        query.sql = notification.sql_query
        query.name = notification.title
        query.save!

        notification.query_id = query.id
        notification.save!
      end
    end
    remove_column :notifications, :sql_query
    change_column :notifications, :query_id, :integer, :null => false
  end

  def down
    add_column :notifications, :sql_query, :text, :after => :body_template
    Notification.connection.schema_cache.clear!
    Notification.reset_column_information
    Query.all.each do |query|
      notification = Notification.where(:query_id => query.id).first
      notification.update_attribute(:sql_query,  query.sql)
      notification.save!
    end
    remove_column :notifications, :query_id
    Query.destroy_all

  end
end

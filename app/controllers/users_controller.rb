# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class UsersController < ApplicationController
  authorize_resource

  active_scaffold :user do |config|
    config.list.columns = [:email, :name, :role]
    config.columns = [:email, :name, :role, :professor, :password, :password_confirmation]
    config.show.link = nil
    config.update.label = :update_user_label
    config.create.label = :create_user_label
    config.columns[:role].form_ui = :select
    config.columns[:password].form_ui = :password
    config.columns[:password_confirmation].form_ui = :password
    config.columns[:professor].form_ui = :record_select

    config.actions.exclude :deleted_records

    config.action_links.add 'create_students', 
      :label => I18n.t('active_scaffold.create_students_action'), 
      :type => :collection
  end

  def create_students
    @students = Student.where_without_user
    #puts @students.to_sql
    @email = CustomVariable.account_email
    
    respond_to_action(:create_students)
  end

  def apply_create
    puts 'aaaa'
    puts params
    process_action_link_action do
      self.successful  = true
    end
#      flash[:info] = 'custom method called'
 #     list
  end

  protected
  def create_students_respond_to_js
    render :partial => 'create_students'
  end

end

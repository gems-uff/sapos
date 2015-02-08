# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ApplicationController < ActionController::Base
  protect_from_forgery

  check_authorization :unless => :devise_controller?

  skip_authorization_check :only => [:root]

  before_filter :authenticate_user!
  before_filter :parse_date

  clear_helpers


  ActiveScaffold.set_defaults do |config|
    config.ignore_columns.add [:created_at, :updated_at, :lock_version, :versions]
    config.create.link.label = :create_link
    config.delete.link.label = "<i title='#{I18n.t('active_scaffold.delete_link')}' class='fa fa-trash-o'></i>".html_safe
    config.show.link.label = "<i title='#{I18n.t('active_scaffold.show_link')}' class='fa fa-eye'></i>".html_safe
    config.update.link.label = "<i title='#{I18n.t('active_scaffold.update_link')}' class='fa fa-pencil'></i>".html_safe
   #config.update.link.html_options[:link] = '<i class="fa fa-pencil"></i>'
    
    config.search.link.label = :search_link
    config.delete.link.confirm = :delete_message
    #Faz com que a busca seja enviada ao servidor enquanto o usuário digita
    config.search.live = true
    #config.search.link.cancel = false        
  end

  # Defines which controller and action should be shown when the base
  # URL is acessed (root route in routes.rb).
  def root
    [Enrollment, Professor, ScholarshipDuration, Phase, Course, City, User].each do |model|
      if can? :read, model
        redirect_to(:controller => model.name.underscore.pluralize.downcase, :action => 'index') and return
      end
    end

  end

  private

  #def authenticate
  #  redirect_to login_url unless User.find_by_id(session[:user_id])
  #end

  # This application has custom values for date inputs, having month and year as default for most dates
  # here we nullify invalid dates that comes from the request
  # invalid dates consists in dates with year < 1000
  def parse_date
    if params[:record]
      external_key = "";
      invalid_year = false;
      params[:record].dup.each { |key, value|
        if key.include?("1i")
          invalid_year = value.to_i < 1000
          external_key = key.split("(")[0]
        end

        if invalid_year
          invalid_year = false
          params[:record].delete_if { |key, value|
            key.include?(external_key)
          }

          params[:record][external_key] = params[:record].delete(external_key)
        end
      }
    end
  end
end

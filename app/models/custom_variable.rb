# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CustomVariable < ActiveRecord::Base
  attr_accessible :description, :value, :variable

  has_paper_trail

  VARIABLES = {
    "single_advisor_points" => :text,
    "multiple_advisor_points" => :text,
    "program_level" => :text,
    "identity_issuing_country" => :text,
    "class_schedule_text" => :text,
    "redirect_email" => :text,
    "notification_footer" => :text,
  }

  validates :variable, :presence => true


  def self.single_advisor_points
  	config = CustomVariable.find_by_variable(:single_advisor_points)
  	config.nil? ? 1.0 : config.value.to_f 
  end

  def self.multiple_advisor_points
  	config = CustomVariable.find_by_variable(:multiple_advisor_points)
  	config.nil? ? 0.5 : config.value.to_f 
  end

  def self.program_level
    config = CustomVariable.find_by_variable(:program_level)
    config.nil? ? nil : config.value.to_i 
  end

  def self.identity_issuing_country
    config = CustomVariable.find_by_variable(:identity_issuing_country)
    Country.find_by_name(config.nil? ? "Brasil": config.value)
  end

  def self.class_schedule_text
    config = CustomVariable.find_by_variable(:class_schedule_text)
    config.nil? ? "" : config.value
  end

  def self.redirect_email
    config = CustomVariable.find_by_variable(:redirect_email)
    config.nil? ? nil : (config.value || '')
  end

  def self.notification_footer
    config = CustomVariable.find_by_variable(:notification_footer)
    config.nil? ? "" : config.value
  end

end

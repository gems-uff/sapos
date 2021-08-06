# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CustomVariable < ApplicationRecord
  has_paper_trail

  VARIABLES = {
    "single_advisor_points" => :text,
    "multiple_advisor_points" => :text,
    "program_level" => :text,
    "identity_issuing_country" => :text,
    "class_schedule_text" => :text,
    "redirect_email" => :text,
    "notification_footer" => :text,
    "minimum_grade_for_approval" => :text,
    "grade_of_disapproval_for_absence" => :text,
    "professor_login_can_post_grades" => :text,
    "account_email" => :text,
  }

  validates :variable, :presence => true
  validate :check_constraints_between_variables
  before_destroy :validate_destroy
  before_validation :validate_create, :on => :create

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

  def self.minimum_grade_for_approval
    config = CustomVariable.find_by_variable(:minimum_grade_for_approval)
    if config.nil? or config.value.blank?
      return 60
    else
      return ((config.value.tr(',','.').to_f)*10.0).to_i
    end	    
  end

  def self.grade_of_disapproval_for_absence
    config = CustomVariable.find_by_variable(:grade_of_disapproval_for_absence)
    if config.nil? or config.value.blank?
      return nil
    else      
      return ((config.value.tr(',', '.').to_f)*10.0).to_i
    end
  end

  def self.professor_login_can_post_grades
    config = CustomVariable.find_by_variable(:professor_login_can_post_grades)
    if (!config.nil?) && (!config.value.nil?)
      formatted_value = config.value.strip.downcase
      if (formatted_value == "yes") || (formatted_value == "yes_all_semesters")
        return formatted_value
      end
    else
      return "no"
    end    
  end

  def self.account_email
    config = CustomVariable.find_by_variable(:account_email)
    config.nil? ? nil : config.value
  end


  def to_label
    "#{self.variable}"
  end	  

  private

  def check_constraints_between_variables
    case self.variable
    when "minimum_grade_for_approval"
      self.errors.add(:value, I18n.translate("activerecord.errors.models.custom_variable.minimum_grade_for_approval_not_gt_grade_of_disapproval_for_absence", :minimum_grade_for_approval=>(self.value.blank? ? 6.0 : self.value.tr(',','.')).to_s, :grade_of_disapproval_for_absence=>(CustomVariable.grade_of_disapproval_for_absence.to_f/10.0).to_s)) if (not CustomVariable.grade_of_disapproval_for_absence.nil? ) and (   ( (self.value.blank?) and ( CustomVariable.grade_of_disapproval_for_absence >= 60 ) )   or   ( (not self.value.blank?) and ( CustomVariable.grade_of_disapproval_for_absence >= ((self.value.tr(',','.').to_f)*10.0).to_i  )    ) )
    when "grade_of_disapproval_for_absence"
      self.errors.add(:value, I18n.translate("activerecord.errors.models.custom_variable.grade_of_disapproval_for_absence_not_lt_minimum_grade_for_approval", :grade_of_disapproval_for_absence=>self.value.tr(',','.'),:minimum_grade_for_approval=>(CustomVariable.minimum_grade_for_approval.to_f/10.0).to_s)) if (not self.value.blank?) and ( ((self.value.tr(',','.').to_f)*10.0).to_i >= CustomVariable.minimum_grade_for_approval )
    end
  end

  def validate_destroy
    case self.variable
    when "minimum_grade_for_approval"
      self.errors.add(:base, I18n.translate("activerecord.errors.models.custom_variable.validate_destroy_of_minimum_grade_for_approval")) if (not CustomVariable.grade_of_disapproval_for_absence.nil?) and ( CustomVariable.grade_of_disapproval_for_absence >= 60 )      
    end	    
    self.errors.blank?
  end

  def validate_create
    case self.variable
    when "minimum_grade_for_approval", "grade_of_disapproval_for_absence"
      if not CustomVariable.find_by_variable(self.variable).nil?
        self.errors.add(:base, I18n.translate("activerecord.errors.models.custom_variable.check_duplicate", :variable=>self.variable))	
      end      
    end
  end	  

end

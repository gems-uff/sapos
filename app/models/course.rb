# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Course < ActiveRecord::Base
  belongs_to :research_area
  # attr_accessible :name, :code, :content, :credits, :workload, :available

  has_many :research_areas, :through => :course_research_areas
  has_many :course_research_areas, :dependent => :destroy

  belongs_to :course_type
  has_many :course_classes, :dependent => :restrict_with_exception

  has_paper_trail

  validates :course_type, :presence => true
  validates :name, :presence => true, :uniqueness => {:scope => :available, :message => "e #{I18n.t('activerecord.attributes.course.available')} #{I18n.t('errors.messages.taken')}"}
  validates :code, :presence => true, :uniqueness => true
  validates :credits, :presence => true
  validates :workload, :presence => true

  def to_label
       "#{self.name}"
  end

  def workload_value
    workload.nil? ? 0 : workload
  end

  def workload_text
    return I18n.translate('activerecord.attributes.course.empty_workload') if workload.nil?
    I18n.translate('activerecord.attributes.course.workload_time', :time => workload)
  end  
end

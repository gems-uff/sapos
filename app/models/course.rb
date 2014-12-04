# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Course < ActiveRecord::Base
  attr_accessible :name, :code, :content, :credits, :workload, :available

  belongs_to :research_area
  belongs_to :course_type
  has_many :course_classes, :dependent => :restrict

  has_paper_trail

  validates :course_type, :presence => true
  validates :name, :presence => true, :uniqueness => true
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

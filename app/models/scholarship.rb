# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Scholarship < ActiveRecord::Base
  belongs_to :level
  belongs_to :sponsor
  belongs_to :scholarship_type
  belongs_to :professor
  has_many :scholarship_durations, :dependent => :destroy
  has_many :enrollments, :through => :scholarship_durations

  has_paper_trail

  validates :scholarship_number, :presence => true, :uniqueness => true
  validates :level, :presence => true
  validates :sponsor, :presence => true

  #validates date
  validates_date :end_date, :on_or_after => :start_date, :allow_nil => true
  
  def to_label
    "#{scholarship_number}"
  end
  
end

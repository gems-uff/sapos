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
  
  before_save :update_end_date

  def to_label
    "#{scholarship_number}"
  end

  def last_date
    return (Date.today + 100.years).end_of_month if self.end_date.nil?
     self.end_date.end_of_month
  end

  def update_end_date
    self.end_date = self.end_date.end_of_month unless self.end_date.nil?
  end

end

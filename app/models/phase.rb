# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Phase < ActiveRecord::Base
  attr_accessible :name, :is_language
  has_many :accomplishments, :dependent => :restrict
  has_many :enrollments, :through => :accomplishments
  has_many :phase_durations, :dependent => :destroy
  has_many :levels, :through => :phase_durations
  has_many :deferral_type, :dependent => :restrict
  has_many :phase_completions, :dependent => :destroy

  has_paper_trail
  
  validates :name, :presence => true, :uniqueness => true

  def to_label
  	"#{self.name}"
  end

  def calculate_end_date(initial_date, total_semesters, total_months, total_days)
    end_date = initial_date

    if total_semesters != 0
      months_from_semesters = (12 * (total_semesters / 2)) + ((end_date.month == 3 ? 5 : 7) * (total_semesters % 2)) - 1
      end_date = months_from_semesters.months.since(end_date).end_of_month
    end

    end_date = total_months.months.since(end_date).end_of_month

    end_date = total_days.days.since(end_date)
  end
end

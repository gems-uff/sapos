# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Level < ActiveRecord::Base
  attr_accessible :name

  has_paper_trail

  has_many :advisement_authorizations, :dependent => :destroy
  has_many :enrollments, :dependent => :restrict
  has_many :majors, :dependent => :restrict
  has_many :phase_durations, :dependent => :restrict
  has_many :scholarships, :dependent => :restrict


  validates :name, :presence => true, :uniqueness => true

  def to_label
  	"#{self.name}"
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class City < ActiveRecord::Base
  belongs_to :state
  has_many :students, :dependent => :restrict_with_exception
  has_many :student_birth_cities, :class_name => 'Student', :foreign_key => 'birth_city_id', :dependent => :restrict_with_exception
  has_many :professors, :dependent => :restrict_with_exception
  
  has_paper_trail

  validates :state, :presence => true

  validates :name, :presence => true

  def to_label
  	"#{self.name}"
  end
end

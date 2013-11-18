# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class State < ActiveRecord::Base
  attr_accessible :name, :code, :country
  belongs_to :country
  has_many :cities, :dependent => :restrict
  has_many :student_birth_states, :class_name => 'Student', :foreign_key => 'birth_state_id', :dependent => :restrict
  
  has_paper_trail
  
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :country, :presence => true

  def to_label
    "#{self.name}"
  end
end

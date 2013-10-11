# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class State < ActiveRecord::Base
  attr_accessible :name, :code, :country
  belongs_to :country
  has_many :cities

  has_paper_trail
  
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :country, :presence => true
end

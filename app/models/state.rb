# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class State < ActiveRecord::Base
  belongs_to :country
  has_many :cities
  
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :country, :presence => true
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Institution < ActiveRecord::Base
  attr_accessible :name, :code
  has_many :majors, :dependent => :destroy
  
  validates :name, :presence => true, :uniqueness => true
end
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Level < ActiveRecord::Base
  attr_accessible :name
  has_many :advisement_authorizations

  has_paper_trail

  validates :name, :presence => true, :uniqueness => true
end

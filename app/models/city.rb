# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class City < ActiveRecord::Base
  belongs_to :state

  validates :state, :presence => true

  validates :name, :presence => true
end

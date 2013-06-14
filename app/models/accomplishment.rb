# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase

  validates :enrollment, :presence => true
  validates :phase, :presence => true

  def to_label
    "#{phase.name}"    
  end
  
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Configuration < ActiveRecord::Base
  attr_accessible :name, :value, :variable

  validates :variable, :presence => true


  def self.single_advisor_points
  	config = Configuration.find_by_variable(:single_advisor_points)
  	config.nil? ? 1.0 : config.value.to_f 
  end

  def self.multiple_advisor_points
  	config = Configuration.find_by_variable(:multiple_advisor_points)
  	config.nil? ? 0.5 : config.value.to_f 
  end

end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class QueryParam < ActiveRecord::Base
  belongs_to :query
  attr_accessible :name, :default_value, :value_type


  VALUE_TYPES = %w{String Number List Date DateTime Literal}

  validates :value_type, presence: true, inclusion: VALUE_TYPES
  validates :name, presence: true, :format => /^([a-z_][a-zA-Z_0-9]+)?$/


end

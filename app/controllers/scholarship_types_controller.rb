# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ScholarshipTypesController < ApplicationController
  authorize_resource

  active_scaffold :scholarship_type do |config|
  	config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_scholarship_type_label
    config.columns = [:name]
  end

end 
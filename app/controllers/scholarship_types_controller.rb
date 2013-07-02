# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ScholarshipTypesController < ApplicationController
  authorize_resource

  active_scaffold :scholarship_type do |conf|
  end

end 
# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentHoldsController < ApplicationController
  authorize_resource
  active_scaffold :"enrollment_hold" do |config|
    config.create.label = :create_enrollment_hold_label
  	config.columns = [:enrollment, :year, :semester, :number_of_semesters, :active]
  	config.actions.swap :search, :field_search
    config.field_search.columns = [:enrollment, :active]
    config.columns[:enrollment].search_ui = :text
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    
    config.columns[:enrollment].form_ui = :record_select
  	config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
    	:options => ['1', '2'],
    	:include_blank => true,
        :default => nil,
    }
    config.columns[:year].options = {
    	:options => ((Date.today.year-10)..(Date.today.year+10)).map { |y| y },
    	:include_blank => true,
        :default => nil,
    }

    config.actions.exclude :deleted_records
  end
end

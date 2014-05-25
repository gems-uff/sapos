# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ReportConfigurationsController < ApplicationController
  authorize_resource

  active_scaffold :report_configuration do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_report_configuration_label
    config.update.label = :update_report_configuration_label
  
    columns = [
		:name, 
		:image,
		:scale,
		:x,
		:y,
		:order, 
		:text, 
		:show_sapos, 
		:use_at_report, 
		:use_at_transcript,
		:use_at_grades_report,
		:use_at_schedule
	]
	

    config.list.columns = [
		:name, 
		:order, 
		:text, 
		:show_sapos, 
		:use_at_report, 
		:use_at_transcript,
		:use_at_grades_report,
		:use_at_schedule
	]

	config.columns = columns
	config.create.columns = columns + [:preview]
	config.update.columns = columns + [:preview]

  end
end
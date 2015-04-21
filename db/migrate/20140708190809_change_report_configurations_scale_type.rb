# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ChangeReportConfigurationsScaleType < ActiveRecord::Migration
  def change
  	change_column :report_configurations, :scale, :decimal, :precision => 10, :scale => 8
  end
end

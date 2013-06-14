# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ResearchAreasController < ApplicationController
  active_scaffold :research_area do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code]
    config.create.label = :create_research_area_label
    config.update.label = :update_research_area_label

    config.columns =
        [:name,
         :code]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end
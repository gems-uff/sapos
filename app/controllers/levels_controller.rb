class LevelsController < ApplicationController
  active_scaffold :level do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_level_label
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name'
end 
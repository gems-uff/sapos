class LevelsController < ApplicationController
  active_scaffold :level do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_level_label
  end
end 
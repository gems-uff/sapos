class LevelsController < ApplicationController
  active_scaffold :level do |config|
    config.list.sorting = {:name => 'ASC'}
  end
end 
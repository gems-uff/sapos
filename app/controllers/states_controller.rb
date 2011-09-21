class StatesController < ApplicationController
  active_scaffold :state do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code, :country]
    config.create.label = :create_state_label
    config.columns[:country].form_ui = :select
    config.create.columns = [:country, :name, :code]
    config.update.label = :update_state_label
    config.update.columns = [:country, :name, :code]
  end
end
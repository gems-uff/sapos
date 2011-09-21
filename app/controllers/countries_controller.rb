class CountriesController < ApplicationController
  active_scaffold :country do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name]
    config.create.label = :create_country_label
    config.create.columns = [:name]
    config.update.label = :update_country_label
    config.update.columns = [:name]
  end
end 
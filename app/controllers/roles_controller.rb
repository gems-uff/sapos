class RolesController < ApplicationController
  active_scaffold :role do |config|
    config.columns = [:id, :name, :description]
    config.columns[:description].form_ui = :textarea
  end
end
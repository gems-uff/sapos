class DismissalReasonsController < ApplicationController
  active_scaffold :dismissal_reason do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_dismissal_reason_label
  end  
end 
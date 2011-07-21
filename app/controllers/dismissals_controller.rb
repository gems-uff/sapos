class DismissalsController < ApplicationController
  active_scaffold :dismissal do |config|
    #config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_dismissal_label
  end
end 
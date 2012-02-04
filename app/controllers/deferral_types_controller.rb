class DeferralTypesController < ApplicationController
  active_scaffold :deferral_type do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description, :duration, :phase]
    config.create.label = :create_deferral_type_label
    config.columns[:phase].clear_link
    config.columns[:phase].form_ui = :select
    config.create.columns = [:name, :description, :duration, :phase]
    config.update.columns = [:name, :description, :duration, :phase]
    config.show.columns = [:name, :description, :duration, :phase]
  end
end

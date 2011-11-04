class DeferralsController < ApplicationController
  active_scaffold :deferral do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment, :deferral_type, :approval_date]
    config.create.label = :create_deferral_label
    config.columns[:enrollment].form_ui = :record_select
    config.create.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.update.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.show.columns = [:enrollment, :approval_date, :obs, :deferral_type]
  end
end 
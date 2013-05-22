class DeferralsController < ApplicationController
  active_scaffold :deferral do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.search.columns = [:enrollment]
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.list.columns = [:enrollment, :approval_date, :deferral_type]
    config.create.label = :create_deferral_label
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:deferral_type].form_ui = :select
    config.columns[:deferral_type].clear_link
    config.columns[:enrollment].clear_link
    config.columns[:approval_date].options = {:format => :monthyear}
    config.create.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.update.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.show.columns = [:enrollment, :approval_date, :obs, :deferral_type]
  end

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end
end 
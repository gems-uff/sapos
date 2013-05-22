class AccomplishmentsController < ApplicationController
  active_scaffold :accomplishment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.search.columns = [:enrollment]
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.columns[:conclusion_date].options = {:format => :monthyear}
    config.list.columns = [:enrollment, :phase, :conclusion_date, :obs]
    config.create.label = :create_accomplishment_label
    config.search.columns = [:phase]
    config.columns[:phase].form_ui = :select
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:enrollment].clear_link
    config.columns[:phase].clear_link
    config.create.columns = [:phase, :enrollment, :conclusion_date, :obs]
    config.update.columns = [:phase, :enrollment, :conclusion_date, :obs]
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
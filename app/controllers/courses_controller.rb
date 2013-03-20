class CoursesController < ApplicationController
  active_scaffold :course do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_course_label
    #este abaixo não está funcionando...
    config.update.label = :update_course_label

    config.columns[:institution].clear_link
    config.columns[:level].clear_link
    config.columns[:students].clear_link
    config.columns[:level].form_ui = :select
    config.columns[:institution].form_ui = :record_select
    config.columns[:students].form_ui = :record_select
    config.create.columns = [:name, :level, :institution, :students]
    config.update.columns = [:name, :level, :institution, :students]

  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

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
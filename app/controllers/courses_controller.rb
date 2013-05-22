class CoursesController < ApplicationController
  active_scaffold :course do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code, :research_area, :credits, :course_type]
    config.create.label = :create_course_label
    config.update.label = :update_course_label

    config.columns[:research_area].clear_link
    config.columns[:course_type].clear_link
    config.columns[:research_area].form_ui = :record_select
    config.columns[:course_type].form_ui = :select

    config.columns =
        [:name, :code, :credits, :research_area, :content, :course_type]
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
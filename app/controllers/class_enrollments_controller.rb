# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentsController < ApplicationController
  active_scaffold :class_enrollment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment,:course_class, :situation, :grade, :disapproved_by_absence]
    config.create.label = :create_class_enrollment_label
    config.update.label = :update_class_enrollment_label

    config.columns[:enrollment].clear_link
    config.columns[:course_class].clear_link
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:situation].form_ui = :select
    config.columns[:grade].options =  {:format => :i18n_number, :i18n_options => {:format_as => "grade"}}
    config.columns[:situation].options = {:options => ClassEnrollment::SITUATIONS, :include_blank => I18n.t("active_scaffold._select_")}

    config.columns =
        [:enrollment, :course_class, :situation, :grade, :disapproved_by_absence, :obs]

  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 
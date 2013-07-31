# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ClassEnrollmentsHelper
  def grade_form_column(record, options)
    options = options.merge({:maxlength => 5, :class => "grade-input numeric-input text-input"})
    text_field :record, :grade_to_view, options
  end
end
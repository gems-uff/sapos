# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::FormTemplatesHelper
  def form_field_t(key, *args)
    t("activerecord.attributes.admissions/form_field.#{key}", *args)
  end

  def student_t(key, *args)
    t("activerecord.attributes.student.#{key}", *args)
  end
end

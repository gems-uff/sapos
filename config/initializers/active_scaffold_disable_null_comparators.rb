# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

ActiveScaffold::Helpers::SearchColumnHelpers.module_eval do
  def include_null_comparators?(column, ui_options: column.options)
    return ui_options[:null_comparators] if ui_options.key?(:null_comparators)

    false
  end
end

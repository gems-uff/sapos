# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module I18nModel
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def record_i18n_attr(text)
      i18n_scope = self.i18n_scope.to_s
      keys = self.lookup_ancestors.flat_map do |klass|
        "#{i18n_scope}.attributes.#{klass.model_name.i18n_key}.#{text}"
      end
      I18n.t(keys.first)
    end
  end

  def record_i18n_attr(text)
    self.class.record_i18n_attr(text)
  end
end

ActiveRecord::Base.include I18nModel

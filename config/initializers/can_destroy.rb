# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ActiveRecord::Base
  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      assoc.options[:dependent] != :restrict ||
        (assoc.macro == :has_one && self.send(assoc.name).nil?) ||
        (assoc.macro == :has_many && self.send(assoc.name).empty?)
    end
  end
end

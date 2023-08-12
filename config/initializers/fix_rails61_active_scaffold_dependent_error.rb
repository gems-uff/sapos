# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# In Rails >= 6.1, when an child model fails its validation
# during the saving of a parent model,
# ActiveScaffold tries to access the to_sym method of the Error
# and raises an exception.
# Defining a to_sym method fixes the problem

ActiveModel::Error.class_eval do
  def to_sym
    self.to_s.to_sym
  end
end

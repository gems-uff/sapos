# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Exceptions
  class VariableException < StandardError; end
  class InvalidStudentFieldException < StandardError; end
  class MissingFieldException < StandardError
    def initialize(msg, exception_type = "missing_field")
      @exception_type = exception_type
      super(msg)
    end
  end
end

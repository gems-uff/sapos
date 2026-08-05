# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CarrierwaveOrphanFile < ApplicationRecord
  def self.last_scanned_at
    maximum(:created_at)
  end
end

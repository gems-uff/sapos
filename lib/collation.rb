# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Collation
  def self.collations
    if ApplicationRecord.connection.adapter_name == "SQLite"
      {
        db_collation: "BINARY",
        value_collation: "BINARY"
      }
    else
      {
        db_collation: "utf8mb4_unicode_520_ci",
        value_collation: "utf8_unicode_520_ci"
      }
    end
  end
end

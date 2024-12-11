# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddQrCodeSignatureToReportConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :report_configurations, :qr_code_signature, :boolean, default: false
  end
end

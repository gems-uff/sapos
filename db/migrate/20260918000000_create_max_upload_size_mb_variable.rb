# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateMaxUploadSizeMbVariable < ActiveRecord::Migration[7.1]
  def up
    CustomVariable.where(variable: "max_upload_size_mb").first ||
      CustomVariable.create!(
        description: "Tamanho máximo, em MB, de cada arquivo enviado nos formulários de inscrição",
        variable: "max_upload_size_mb",
        value: "15"
      )
  end

  def down
    CustomVariable.where(variable: "max_upload_size_mb").destroy_all
  end
end

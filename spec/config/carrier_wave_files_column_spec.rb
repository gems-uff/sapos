# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Os arquivos enviados moram em carrier_wave_files.binary. A coluna precisa
# comportar o limite de upload (15 MB, FilledFormField#size_of_file): em
# MariaDB, sem limite declarado ela vira BLOB, de 64 KB (#230, #737). O banco
# de teste e montado pelo db/schema.rb, entao este exemplo acusa um schema.rb
# regenerado que perca o limite.
RSpec.describe "Coluna dos arquivos enviados" do
  it "comporta arquivos de ate 16 MB" do
    coluna = ActiveRecord::Base.connection.columns(:carrier_wave_files).find { |c| c.name == "binary" }

    expect(coluna.limit).to be >= 16_777_215
  end
end

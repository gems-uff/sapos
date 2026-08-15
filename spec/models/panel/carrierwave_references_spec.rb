# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O "Coletor de lixo" do Painel apaga FISICAMENTE (delete_all / do_destroy) os
# arquivos que a varredura Mark-and-Sweep marcou como orfaos. A marcacao confia em
# DUAS listas mantidas a mao, que precisam cobrir TODOS os pontos de upload:
#
#   * Panel::CarrierwaveFilesHelper::CARRIERWAVE_REFERENCES -- de onde a varredura
#     descobre quem referencia cada carrier_wave_file;
#   * o include de CarrierWaveFileCleanup no model -- que remove a linha orfa
#     quando o arquivo deixa de ser referenciado pela aplicacao.
#
# Se alguem adicionar um mount_uploader novo e esquecer de atualizar a primeira
# lista, a varredura marcaria arquivo VIVO como orfao e o delete_all o destruiria.
# Este spec congela a invariante: hoje ela vale, e uma coluna montada nova que fuja
# das listas quebra o teste antes de virar perda de dados em producao.
RSpec.describe "Cobertura das referencias de carrier_wave_files", type: :model do
  # Varre apenas os models da aplicacao (nao gems) atras de mount_uploader, para
  # nao gerar falso positivo com uploaders de bibliotecas. Devolve pares
  # [classe_do_model, coluna].
  def app_mounted_columns
    root = Rails.root.join("app", "models")
    root.glob("**/*.rb").flat_map do |path|
      columns = path.read.scan(/mount_uploader\s+:(\w+)/).flatten
      next [] if columns.empty?

      name = path.relative_path_from(root).to_s.delete_suffix(".rb").camelize
      columns.map { |column| [name.constantize, column] }
    end
  end

  let(:references) { Panel::CarrierwaveFilesHelper::CARRIERWAVE_REFERENCES }

  it "enxerga os tres uploaders montados hoje" do
    pairs = app_mounted_columns.map { |klass, column| [klass.table_name, column] }

    expect(pairs).to contain_exactly(
      ["students", "photo"],
      ["report_configurations", "image"],
      ["filled_form_fields", "file"]
    )
  end

  it "lista cada coluna montada em CARRIERWAVE_REFERENCES (chave medium_hash)" do
    app_mounted_columns.each do |klass, column|
      entry = [klass.table_name, column, "medium_hash"]

      expect(references).to include(entry),
        "Falta #{entry.inspect} em CARRIERWAVE_REFERENCES: a varredura marcaria " \
        "#{klass.name}##{column} como orfao e o delete_all apagaria arquivo vivo."
    end
  end

  it "faz cada model que monta uploader incluir CarrierWaveFileCleanup" do
    app_mounted_columns.each do |klass, column|
      expect(klass.include?(CarrierWaveFileCleanup)).to be(true),
        "#{klass.name} monta :#{column} mas nao inclui CarrierWaveFileCleanup: a " \
        "linha em carrier_wave_files ficaria orfa ao apagar pela aplicacao."
    end
  end

  # reports referencia o arquivo por chave estrangeira (id), nao por medium_hash,
  # entao nao aparece como mount_uploader -- mas ainda precisa estar na lista.
  it "mantem a referencia por FK de reports (carrierwave_file_id)" do
    expect(references).to include(["reports", "carrierwave_file_id", "id"])
    expect(Report.reflect_on_association(:carrierwave_file)).to be_present
  end
end

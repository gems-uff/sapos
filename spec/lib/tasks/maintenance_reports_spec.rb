# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Depois da #631 quem recusa o download e Report#expired?, e esta rotina ficou
# sendo so o desligamento do documento do arquivo. As duas decisoes precisam
# concordar sobre qual documento esta vencido, e concordam por sairem de
# Report.expiry_cutoff -- o escopo aqui, o predicado no controlador. Este
# arquivo prende a rotina a esse escopo: sem ele, a data podia voltar a ser
# escrita a mao na rake e ninguem notaria.
#
# A linha em carrier_wave_files fica em todos os exemplos: a storage deduplica
# pelo conteudo, a linha pode ter outro dono, e so o coletor de orfaos (#597)
# apaga -- ver Report#release_file!.
RSpec.describe "maintenance:remove_expired_reports", type: :task do
  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    Rake::Task["maintenance:remove_expired_reports"].reenable
    @user = FactoryBot.create(:user)
  end

  def report_with_file(expires_at)
    file = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.create!(
      original_filename: "documento.pdf", content_type: "application/pdf",
      binary: "conteudo", medium_hash: SecureRandom.hex(16)
    )
    FactoryBot.create(
      :report, user: @user, carrierwave_file: file, expires_at: expires_at
    )
  end

  it "esvazia o vencido e poupa o que ainda vale, no mesmo limite do escopo" do
    vencido = report_with_file(Date.yesterday)
    no_dia = report_with_file(Date.today)
    futuro = report_with_file(Date.tomorrow)
    arquivo_do_vencido = vencido.carrierwave_file_id

    Rake::Task["maintenance:remove_expired_reports"].invoke

    expect(vencido.reload.carrierwave_file_id).to be_nil
    expect(no_dia.reload.carrierwave_file_id).to be_present
    expect(futuro.reload.carrierwave_file_id).to be_present
    expect(
      CarrierWave::Storage::ActiveRecord::ActiveRecordFile.exists?(arquivo_do_vencido)
    ).to be true
  end

  # A limpeza nao invalida: quem passou por aqui fica sem arquivo e com
  # invalidated_at nulo, e e por isso que o predicado do controlador mede o
  # arquivo em vez da invalidacao.
  it "nao marca como invalidado o que apenas venceu" do
    vencido = report_with_file(Date.yesterday)

    Rake::Task["maintenance:remove_expired_reports"].invoke

    expect(vencido.reload.invalidated_at).to be_nil
    expect(vencido.invalidated_by).to be_nil
  end

  # carrierwave_file_id pode apontar para uma linha que nao existe (#696): a FK
  # so existe em banco que passou pelas migrations, nao no carregado do
  # schema.rb (suite, CI) nem em replica carregada por dump sem checagem, e foi
  # assim que a homologacao chegou com carrier_wave_files vazia e um report
  # vencido apontando para o nada. O "quebrado" e criado antes do "valido" para
  # que o find_each, que percorre por id, passe por ele primeiro -- e e isso que
  # prova que a task continua depois dele em vez de abortar.
  it "nao aborta quando um vencido aponta para um arquivo que nao existe mais" do
    quebrado = report_with_file(Date.yesterday)
    CarrierWave::Storage::ActiveRecord::ActiveRecordFile
      .where(id: quebrado.carrierwave_file_id).delete_all
    valido = report_with_file(Date.yesterday)
    arquivo_do_valido = valido.carrierwave_file_id

    expect { Rake::Task["maintenance:remove_expired_reports"].invoke }.not_to raise_error

    expect(quebrado.reload.carrierwave_file_id).to be_nil
    expect(valido.reload.carrierwave_file_id).to be_nil
    expect(
      CarrierWave::Storage::ActiveRecord::ActiveRecordFile.exists?(arquivo_do_valido)
    ).to be true
  end
end

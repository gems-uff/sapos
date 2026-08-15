# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O bloco de fase do formulario de edicao da candidatura
# (_custom_forms_form_column.html.erb) imprimia a data de inicio do processo nas
# DUAS linhas: a de "Data de fim" repetia start_date. Alem disso as datas eram
# interpoladas cruas, contando com o monkey-patch global de Date#to_s (#625).
#
# Esta tela nao e alcancavel pela varredura estatica da homologacao -- custom_forms
# so esta em config.update.columns, entao ela existe apenas na edicao.
RSpec.describe "Admissions::AdmissionApplications edit form dates", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "edit_dates_admin@ic.uff.br")
    sign_in @admin

    @process = FactoryBot.create(
      :admission_process,
      start_date: Date.new(2018, 3, 1), end_date: Date.new(2018, 6, 30)
    )
    @application = FactoryBot.create(
      :admission_application, admission_process: @process
    )
  end

  # A candidatura nasce sem fase, que e o ramo onde estava o defeito.
  it "is on the branch that has no phase yet" do
    expect(@application.admission_phase).to be_nil
  end

  # Sem fase, update_authorized? devolve false na primeira linha
  # ("return false if phase.nil?") e o partial para em "Acesso invalido" antes
  # de montar o bloco. O ramo so e alcancavel pela acao de override, que troca a
  # checagem por can?(:override) mais staff_can_edit -- e por isso o parametro
  # nao e detalhe de teste, e a unica porta para esta tela.
  it "is unreachable without the override, which is what guards the branch" do
    get edit_admission_application_path(@application)

    expect(response.body).to include("Acesso inv")
    expect(response.body).not_to include("Fase atual")
  end

  it "shows the end date of the process, not the start date twice" do
    get edit_admission_application_path(@application, override: true)

    expect(response.body).to include("Fase atual")
    expect(response.body).to include("30/06/2018")
  end

  it "shows the start date too" do
    get edit_admission_application_path(@application, override: true)

    expect(response.body).to include("01/03/2018")
  end

  it "keeps both dates out of the ISO format that Ruby uses by default" do
    get edit_admission_application_path(@application, override: true)

    expect(response.body).not_to include("2018-03-01")
    expect(response.body).not_to include("2018-06-30")
  end
end

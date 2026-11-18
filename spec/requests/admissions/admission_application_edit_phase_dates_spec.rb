# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Ramo "com fase" do cabeçalho da edição da candidatura: as linhas de data
# aparecem conforme a fase do edital, mas imprimem as datas do edital.
RSpec.describe "Datas da fase atual na edição da candidatura", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "phase_dates_admin@ic.uff.br")
    template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(template, simple_url: "phase-dates")
    @process.update!(start_date: Date.new(2018, 3, 1), end_date: Date.new(2018, 6, 30))
    phase = add_phase(@process, 1, name: "Entrevista")
    @process_phase = @process.phases.find_by!(admission_phase: phase)
    @process_phase.update!(start_date: Date.new(2018, 8, 10), end_date: Date.new(2018, 8, 20))
    @application = create_application(@process, fields: { "nota" => "8" }, admission_phase: phase)
  end

  def edit_body
    get edit_admission_application_path(@application, override: true)
    response.body
  end

  it "mostra o bloco da fase atual" do
    expect(edit_body).to include("Entrevista")
  end

  it "omite as datas quando a fase não as tem" do
    @process_phase.update!(start_date: nil, end_date: nil)
    expect(edit_body).not_to include("01/03/2018")
  end

  it "mostra as datas da fase, não as do edital", pending: "issue #764" do
    body = edit_body
    expect(body).to include("10/08/2018")
    expect(body).to include("20/08/2018")
    expect(body).not_to include("01/03/2018")
    expect(body).not_to include("30/06/2018")
  end
end

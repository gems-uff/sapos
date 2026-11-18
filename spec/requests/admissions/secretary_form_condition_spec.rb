# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A condição do comitê e do seletor de ranking é configuração do edital, feita
# pela coordenação ou pelo administrador. A secretaria gerencia o comitê no que
# muda a cada processo seletivo, o nome e os membros, mas não a condição: a
# tela lhe oferece o editor, e o active_scaffold descarta sem aviso o que ela
# grava nele, porque ela não tem permissão sobre FormCondition (issue #777).
RSpec.describe "Condição de comitê e de seletor de ranking para a secretaria", type: :request do
  before(:each) do
    @secretary = create_confirmed_user([FactoryBot.create(:role_secretaria)], "condition_secretary@ic.uff.br", "Sec")
    @coordinator = create_confirmed_user([FactoryBot.create(:role_coordenacao)], "condition_coord@ic.uff.br", "Coord")
    FactoryBot.create(:form_field, name: "linha")
  end

  # O que o editor de condição envia (form_condition_widget.js)
  def condition(value)
    {
      "mode" => Admissions::FormCondition::CONDITION, "form_conditions" => { "0" => "" },
      "field" => "linha", "condition" => Admissions::FormCondition::EQUALS, "value" => value
    }
  end

  def create_committee(name)
    post admission_committees_path, params: { record: { name: name, form_condition: condition("Redes") } }
    Admissions::AdmissionCommittee.find_by!(name: name)
  end

  def create_machine(name)
    post ranking_machines_path, params: { record: { name: name, form_condition: condition("Redes") } }
    Admissions::RankingMachine.find_by!(name: name)
  end

  it "a coordenação vê o editor e grava a condição do comitê e do seletor" do
    sign_in @coordinator
    get new_admission_committee_path
    expect(response.body).to include("create_form_condition(")
    expect(create_committee("Comitê").form_condition.value).to eq("Redes")
    expect(create_machine("Seletor").form_condition.value).to eq("Redes")
  end

  it "a secretaria grava o nome do comitê, e a condição em vigor fica como está" do
    committee = FactoryBot.create(:admission_committee, name: "Comitê",
      form_condition: Admissions::FormCondition.create!(condition("Redes").except("form_conditions")))
    sign_in @secretary
    put admission_committee_path(committee), params: {
      record: { name: "Comitê novo", form_condition: condition("Banco").merge("id" => committee.form_condition_id.to_s) }
    }
    expect(committee.reload.name).to eq("Comitê novo")
    expect(committee.form_condition.value).to eq("Redes")
  end

  it "a tela de comitê não oferece o editor de condição à secretaria", pending: "issue #777" do
    sign_in @secretary
    get new_admission_committee_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("create_form_condition(")
  end

  it "a tela de seletor de ranking não oferece o editor de condição à secretaria", pending: "issue #777" do
    sign_in @secretary
    get new_ranking_machine_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("create_form_condition(")
  end
end

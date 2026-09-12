# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A ação duplicate vem da gem active_scaffold_duplicate, então nenhuma linha dela
# entra na cobertura da aplicação: o número pode chegar a 100% sem que a ação
# rode uma vez. Sete controllers a ligam; até aqui só o de configuração de
# relatório tinha spec. Os seis de admissions usam o link por GET
# (config.duplicate.link.method = :get), que é a extensão de roteamento que a
# gem instala -- POST|GET na rota /:id/duplicate -- e é essa a superfície que um
# major da gem muda.
#
# O GET não grava nada: monta @record a partir de @old_record.dup e renderiza o
# formulário de criação já preenchido. É isso que se afirma aqui, para cada
# controller: 200, nenhum registro novo, e o nome do original dentro do form.
RSpec.describe "Admissions: ação duplicate por GET", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "duplicate_admin@ic.uff.br")
    sign_in @admin
  end

  # Cada caso: [rótulo, factory (com atributos), classe, helper de rota]. O nome
  # é fixado para a asserção não depender de sequence de factory. O helper vai
  # como símbolo porque só existe dentro do exemplo, não no escopo da classe.
  CASES = [
    [
      "template de formulário",
      -> { FactoryBot.create(:form_template, name: "Formulário Original") },
      Admissions::FormTemplate,
      :duplicate_form_template_path
    ],
    [
      "template de consolidação",
      -> {
        FactoryBot.create(
          :form_template,
          name: "Consolidação Original",
          template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
        )
      },
      Admissions::FormTemplate,
      :duplicate_consolidation_template_path
    ],
    [
      "fase",
      -> { FactoryBot.create(:admission_phase, name: "Fase Original") },
      Admissions::AdmissionPhase,
      :duplicate_admission_phase_path
    ],
    [
      "processo de admissão",
      -> {
        FactoryBot.create(
          :admission_process,
          name: "Processo Original", simple_url: "duplicate-original"
        )
      },
      Admissions::AdmissionProcess,
      :duplicate_admission_process_path
    ],
    [
      "configuração de ranking",
      -> { FactoryBot.create(:ranking_config, name: "Ranking Original") },
      Admissions::RankingConfig,
      :duplicate_ranking_config_path
    ],
    [
      "comitê",
      -> { FactoryBot.create(:admission_committee, name: "Comitê Original") },
      Admissions::AdmissionCommittee,
      :duplicate_admission_committee_path
    ]
  ].freeze

  CASES.each do |label, build, klass, path_helper|
    it "abre o formulário de criação preenchido a partir de um #{label}, sem gravar" do
      record = build.call
      before = klass.count

      get public_send(path_helper, record)

      expect(response).to have_http_status(:ok)
      expect(klass.count).to eq(before)
      # O form de criação do active_scaffold ecoa cada coluna em um input com
      # value; o nome do original é o sinal de que @record veio do dup.
      expect(response.body).to include(%(value="#{record.name}"))
    end
  end
end

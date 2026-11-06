# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O formulario publico so oferece ao candidato o que ele pode preencher, mas os
# parametros que chegam ao update sao outra coisa: o que a tela nao oferece tem
# de ser recusado pelo servidor. Cada exemplo manda, na mesma requisicao, uma
# alteracao legitima -- que tem de ser gravada, senao a recusa do resto nao
# prova nada -- e uma que a tela nao oferece.
RSpec.describe "Admissions::ApplyController com parametros fora do formulario", type: :request do
  include AdmissionsScenarioHelpers

  def apply_path_for(application)
    admission_apply_path(
      admission_id: application.admission_process.simple_id, id: application.token
    )
  end

  def field_of(filled_form, name)
    filled_form.fields.joins(:form_field).find_by!(form_field: { name: name })
  end

  describe "resultado de fase" do
    before(:each) do
      template = create_admission_template("Inscricao", {
        "Nome social" => Admissions::FormField::STRING
      })
      @process = FactoryBot.create(
        :admission_process, name: "Mestrado", simple_url: "forjado-#{SecureRandom.hex(4)}",
        form_template: template,
        start_date: Date.today - 40.days,
        end_date: Date.today - 10.days,
        edit_date: Date.today - 5.days
      )
      @phase1 = add_phase(@process, 1,
        consolidation_form: create_consolidation_template("Consolidacao", {
          "Nota" => code_field("{{ 5 }}")
        }),
        shared_form: create_admission_template("Avaliacao", {
          "Entrevista" => Admissions::FormField::STRING
        })
      )
      @phase2 = add_phase(@process, 2,
        candidate_form: create_admission_template("Documentos", {
          "Comprovante" => Admissions::FormField::STRING
        })
      )
      @application = create_application(
        @process, admission_phase: @phase2, fields: { "Nome social" => "Ana" }
      )
      @consolidation = create_phase_result(
        @application, @phase1, Admissions::AdmissionPhaseResult::CONSOLIDATION,
        fields: { "Nota" => "5" }
      )
      @shared = create_phase_result(
        @application, @phase1, Admissions::AdmissionPhaseResult::SHARED,
        fields: { "Entrevista" => "6" }
      )
      @candidate = create_phase_result(
        @application, @phase2, Admissions::AdmissionPhaseResult::CANDIDATE,
        filled: false, fields: { "Comprovante" => "" }
      )
    end

    def candidate_form_entry
      {
        id: @candidate.id, admission_phase_id: @phase2.id,
        mode: Admissions::AdmissionPhaseResult::CANDIDATE,
        filled_form_attributes: {
          id: @candidate.filled_form.id, enable_submission: "1",
          fields_attributes: { "0" => {
            id: field_of(@candidate.filled_form, "Comprovante").id, value: "enviado"
          } }
        }
      }
    end

    def forged_entry(result, field_name, value)
      {
        id: result.id,
        filled_form_attributes: {
          id: result.filled_form.id,
          fields_attributes: { "0" => {
            id: field_of(result.filled_form, field_name).id, value: value
          } }
        }
      }
    end

    it "nao altera a consolidacao de uma fase anterior" do
      put apply_path_for(@application), params: { record: {
        results_attributes: {
          "0" => candidate_form_entry,
          "1" => forged_entry(@consolidation, "Nota", "10"),
        }
      } }

      expect(field_of(@candidate.filled_form, "Comprovante").value).to eq "enviado"
      expect(field_of(@consolidation.filled_form, "Nota").value).to eq "5"
    end

    it "nao altera o formulario compartilhado preenchido pela comissao" do
      put apply_path_for(@application), params: { record: {
        results_attributes: {
          "0" => candidate_form_entry,
          "1" => forged_entry(@shared, "Entrevista", "10"),
        }
      } }

      expect(field_of(@candidate.filled_form, "Comprovante").value).to eq "enviado"
      expect(field_of(@shared.filled_form, "Entrevista").value).to eq "6"
    end

    # A fase atual tem formulario de candidato, e e so por isso que o update
    # esta aberto: a fase nao deixa o candidato editar a inscricao.
    it "nao altera o formulario de inscricao fora do prazo" do
      filled_form = @application.filled_form
      put apply_path_for(@application), params: { record: {
        filled_form_attributes: {
          id: filled_form.id, enable_submission: "1",
          fields_attributes: { "0" => {
            id: field_of(filled_form, "Nome social").id, value: "Outra"
          } }
        },
        results_attributes: { "0" => candidate_form_entry }
      } }

      expect(field_of(@candidate.filled_form, "Comprovante").value).to eq "enviado"
      expect(field_of(filled_form, "Nome social").value).to eq "Ana"
    end
  end

  describe "campo de outro template" do
    before(:each) do
      template = create_admission_template("Inscricao", {
        "Nome social" => Admissions::FormField::STRING,
        "Cota" => {
          field_type: Admissions::FormField::RADIO,
          configuration: { "values" => ["Sim", "Nao"] }
        },
      })
      @process = FactoryBot.create(
        :admission_process, name: "Mestrado", simple_url: "forjado-#{SecureRandom.hex(4)}",
        form_template: template,
        start_date: Date.today - 10.days,
        end_date: Date.today + 10.days,
        edit_date: Date.today + 20.days
      )
      # O template de outro processo, com um campo de mesmo nome: e o que
      # acontece quando o edital do semestre seguinte copia o anterior.
      @foreign_field = create_admission_template("Inscricao antiga", {
        "Cota" => Admissions::FormField::STRING
      }).fields.first
      @application = create_application(
        @process, fields: { "Nome social" => "Ana", "Cota" => "Nao" }
      )
    end

    def submit_main_form(extra_fields = {})
      filled_form = @application.filled_form
      fields = {
        "0" => { id: field_of(filled_form, "Nome social").id, value: "Ana Maria" },
        "1" => { id: field_of(filled_form, "Cota").id, value: "Nao" },
      }.merge(extra_fields)
      put apply_path_for(@application), params: { record: {
        filled_form_attributes: {
          id: filled_form.id, enable_submission: "1", fields_attributes: fields
        }
      } }
    end

    # Aqui o controle vem depois: a submissao com o campo estranho e recusada
    # inteira, e a mesma submissao sem ele tem de ser gravada.
    it "nao grava o campo nem deixa ele tomar o lugar do campo de mesmo nome" do
      filled_form = @application.filled_form
      submit_main_form("2" => { form_field_id: @foreign_field.id, value: "Sim" })

      expect(filled_form.fields.where(form_field: @foreign_field)).to be_empty
      expect(@application.reload.fields_hash["Cota"].value).to eq "Nao"
      expect(field_of(filled_form, "Nome social").value).to eq "Ana"

      submit_main_form

      expect(field_of(filled_form, "Nome social").value).to eq "Ana Maria"
    end

    it "nao troca o template do formulario de inscricao" do
      filled_form = @application.filled_form
      template_id = filled_form.form_template_id
      put apply_path_for(@application), params: { record: {
        filled_form_attributes: {
          id: filled_form.id, enable_submission: "1",
          form_template_id: @foreign_field.form_template_id,
          fields_attributes: {
            "0" => { id: field_of(filled_form, "Nome social").id, value: "Ana Maria" },
          }
        }
      } }

      expect(field_of(filled_form, "Nome social").value).to eq "Ana Maria"
      expect(filled_form.reload.form_template_id).to eq template_id
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Avaliação de condições sobre formulário preenchido (#681): cada operador de
# comparação, a composição E/OU, o tratamento de campo ausente, e a ida e volta
# entre condição e o hash que os campos de código guardam na configuração.
RSpec.describe Admissions::FormCondition, "avaliação", type: :model do
  before(:each) do
    @template = create_admission_template("Inscrição", {
      "nota" => Admissions::FormField::NUMBER,
      "nome" => Admissions::FormField::STRING,
      "data" => Admissions::FormField::DATE,
      "opcoes" => { field_type: Admissions::FormField::COLLECTION_CHECKBOX, configuration: { "values" => ["a", "b", "c"] } },
      "anexo" => Admissions::FormField::FILE,
    })
    @process = create_closed_admission_process(@template, simple_url: "form-condition-spec")
    @application = create_application(@process, fields: {
      "nota" => "8.5", "nome" => "Ana Maria", "data" => "15/03/2020", "opcoes" => ["a", "c"],
      "anexo" => { file: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png") },
    })
    @fields = @application.fields_hash
  end

  def truth(condition, **options)
    Admissions::FormCondition.check_truth(condition, **options) { |name| @fields[name] }
  end

  describe ".check_truth com um operador" do
    {
      [Admissions::FormCondition::CONTAINS, "nome", "Mar"] => true,
      [Admissions::FormCondition::CONTAINS, "nome", "Zé"] => false,
      [Admissions::FormCondition::STARTS_WITH, "nome", "Ana"] => true,
      [Admissions::FormCondition::STARTS_WITH, "nome", "Maria"] => false,
      [Admissions::FormCondition::ENDS_WITH, "nome", "Maria"] => true,
      [Admissions::FormCondition::EQUALS, "nome", "Ana Maria"] => true,
      [Admissions::FormCondition::EQUALS, "nome", "Ana"] => false,
      [Admissions::FormCondition::NEQ, "nome", "Ana"] => true,
      [Admissions::FormCondition::GE, "nota", "8.5"] => true,
      [Admissions::FormCondition::GE, "nota", "9"] => false,
      [Admissions::FormCondition::LE, "nota", "8.5"] => true,
      [Admissions::FormCondition::LE, "nota", "8"] => false,
      [Admissions::FormCondition::GT, "nota", "8"] => true,
      [Admissions::FormCondition::GT, "nota", "8.5"] => false,
      [Admissions::FormCondition::LT, "nota", "9"] => true,
      [Admissions::FormCondition::LT, "nota", "8.5"] => false,
      [Admissions::FormCondition::GE, "data", "01/01/2020"] => true,
      [Admissions::FormCondition::LT, "data", "01/01/2020"] => false,
      [Admissions::FormCondition::NULL, "nome", nil] => false,
      [Admissions::FormCondition::NOT_NULL, "nome", nil] => true,
      ["inexistente", "nome", "Ana"] => false,
    }.each do |(operator, field, value), expected|
      it "#{field} #{operator} #{value.inspect} é #{expected}" do
        expect(truth(field_condition(field, operator, value))).to be expected
      end
    end

    it "compara número como número, não como texto" do
      @fields["nota"].value = "10"
      expect(truth(field_condition("nota", Admissions::FormCondition::GT, "9"))).to be true
    end

    it "vale para qualquer elemento de uma lista" do
      expect(truth(field_condition("opcoes", Admissions::FormCondition::EQUALS, "c"))).to be true
      expect(truth(field_condition("opcoes", Admissions::FormCondition::EQUALS, "b"))).to be false
    end

    it "compara o arquivo só por presença" do
      # O uploader não é texto: só NULL e NOT_NULL fazem sentido sobre ele.
      expect(truth(field_condition("anexo", Admissions::FormCondition::NOT_NULL))).to be true
      expect(truth(field_condition("anexo", Admissions::FormCondition::NULL))).to be false
    end
  end

  describe ".check_truth composta" do
    it "sem condição ou com modo nenhum devolve o default" do
      expect(truth(nil)).to be true
      expect(truth(nil, default: false)).to be false
      expect(truth(Admissions::FormCondition.new(mode: Admissions::FormCondition::NONE), default: false)).to be false
    end

    it "E exige todas e OU basta uma" do
      high = field_condition("nota", Admissions::FormCondition::GE, "8")
      ana = field_condition("nome", Admissions::FormCondition::STARTS_WITH, "Ana")
      ze = field_condition("nome", Admissions::FormCondition::STARTS_WITH, "Zé")

      expect(truth(composed_condition(Admissions::FormCondition::AND, high, ana))).to be true
      expect(truth(composed_condition(Admissions::FormCondition::AND, high, ze))).to be false
      expect(truth(composed_condition(Admissions::FormCondition::OR, ze, ana))).to be true
      expect(truth(composed_condition(Admissions::FormCondition::OR, ze))).to be false
    end

    it "campo ausente é falso por padrão e estoura quando se pede" do
      FactoryBot.create(:form_field, name: "sumido")
      condition = field_condition("sumido", Admissions::FormCondition::NOT_NULL)
      expect(truth(condition)).to be false
      expect { truth(condition, should_raise: Admissions::FormCondition::RAISE_RANKING) }
        .to raise_error(Exceptions::MissingFieldException, I18n.t(
          "errors.admissions/admission_application.field_not_found",
          field: "sumido", source: Admissions::FormCondition::RAISE_RANKING
        ))
    end

    it "propaga should_raise para as subcondições" do
      FactoryBot.create(:form_field, name: "sumido")
      condition = composed_condition(
        Admissions::FormCondition::AND,
        field_condition("sumido", Admissions::FormCondition::NOT_NULL)
      )
      expect { truth(condition, should_raise: Admissions::FormCondition::RAISE_PHASE) }
        .to raise_error(Exceptions::MissingFieldException)
    end
  end

  describe "ida e volta com hash" do
    it "new_from_hash monta a árvore e to_hash a devolve" do
      hash = {
        "mode" => Admissions::FormCondition::AND,
        "temp_id" => "abc",
        "form_conditions" => [
          { "mode" => Admissions::FormCondition::CONDITION, "field" => "nota",
            "condition" => Admissions::FormCondition::GE, "value" => "7" },
          { "mode" => Admissions::FormCondition::OR, "form_conditions" => [
            { "mode" => Admissions::FormCondition::CONDITION, "field" => "nome",
              "condition" => Admissions::FormCondition::CONTAINS, "value" => "Ana" },
          ] },
        ],
      }
      condition = Admissions::FormCondition.new_from_hash(hash)

      expect(condition.mode).to eq(Admissions::FormCondition::AND)
      expect(condition.form_conditions.size).to eq(2)
      expect(condition.form_conditions[1].form_conditions[0].field).to eq("nome")
      expect(truth(condition)).to be true
      expect(condition.to_hash).to eq({
        mode: Admissions::FormCondition::AND, field: nil, condition: nil, value: nil,
        form_conditions: [
          { mode: Admissions::FormCondition::CONDITION, field: "nota",
            condition: Admissions::FormCondition::GE, value: "7", form_conditions: [] },
          { mode: Admissions::FormCondition::OR, field: nil, condition: nil, value: nil,
            form_conditions: [
              { mode: Admissions::FormCondition::CONDITION, field: "nome",
                condition: Admissions::FormCondition::CONTAINS, value: "Ana", form_conditions: [] },
            ] },
        ],
      })
      expect(Admissions::FormCondition.new_from_hash(nil)).to be_nil
    end

    it "to_hash inclui o id de condição gravada" do
      condition = field_condition("nota", Admissions::FormCondition::GE, "7")
      condition.save!
      expect(condition.to_hash[:id]).to eq(condition.id)
    end
  end

  describe "#recursive_simple_validation" do
    it "acusa modo em branco, campo em branco e campo desconhecido, descendo na árvore" do
      condition = Admissions::FormCondition.new(mode: Admissions::FormCondition::AND)
      condition.form_conditions << Admissions::FormCondition.new(mode: Admissions::FormCondition::CONDITION, field: "")
      condition.form_conditions << Admissions::FormCondition.new(mode: Admissions::FormCondition::CONDITION, field: "nao_existe")
      condition.form_conditions << Admissions::FormCondition.new(mode: nil)

      # O retorno do método não é a lista: quem chama passa a lista e a lê.
      errors = []
      condition.recursive_simple_validation(errors:)
      expect(errors).to contain_exactly(
        [:blank_field_error, {}],
        [:invalid_name_error, { field: "nao_existe" }],
        [:blank_mode_error, {}]
      )
    end

    it "não acusa nada numa condição válida" do
      errors = []
      field_condition("nota", Admissions::FormCondition::GE, "7").recursive_simple_validation(errors:)
      expect(errors).to eq([])
    end
  end

  describe "rótulos e pendências" do
    it "to_label descreve a condição simples e junta as compostas" do
      simple = field_condition("nota", Admissions::FormCondition::GE, "7")
      expect(simple.to_label).to eq("nota #{Admissions::FormCondition::GE} 7")
      expect(simple.widget).to eq(simple.to_label)
      other = field_condition("nome", Admissions::FormCondition::EQUALS, "Ana")
      expect(composed_condition(Admissions::FormCondition::AND, simple, other).to_label)
        .to eq("(#{simple.to_label}) & (#{other.to_label})")
      expect(composed_condition(Admissions::FormCondition::OR, simple, other).to_label)
        .to eq("(#{simple.to_label}) | (#{other.to_label})")
    end

    it "widget= é aceito e ignorado, para o formulário do active_scaffold" do
      condition = field_condition("nota", Admissions::FormCondition::GE, "7")
      condition.widget = "qualquer"
      expect(condition.widget).to eq(condition.to_label)
    end

    it "update_pendencies alcança o comitê da condição e o pai" do
      phase = add_phase(@process, 1)
      phase.update!(member_form: create_admission_template("Parecer", { "p" => Admissions::FormField::STRING }))
      reviewer = professor_user("cond-reviewer@ic.uff.br")
      child = field_condition("nota", Admissions::FormCondition::GE, "9")
      parent = composed_condition(Admissions::FormCondition::AND, child)
      parent.save!
      add_committee(phase, [reviewer], form_condition: parent)
      @application.update!(admission_phase: phase)
      phase.create_pendencies_for_candidate(@application)
      expect(@application.pendencies.where(mode: Admissions::AdmissionPendency::MEMBER).pluck(:user_id)).to eq([nil])

      # Pela tela a condição chega como objeto novo; aqui o mesmo objeto em
      # memória guardaria o cache vazio de comitês do pai.
      Admissions::FormCondition.find(child.id).update!(value: "8")

      expect(@application.pendencies.reload.where(mode: Admissions::AdmissionPendency::MEMBER).pluck(:user_id))
        .to eq([reviewer.id])
    end
  end
end

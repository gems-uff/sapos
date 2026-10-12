# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"


RSpec.describe Admissions::FilledForm, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_one(:admission_application).dependent(:restrict_with_exception) }
  it { should have_one(:letter_request).dependent(:restrict_with_exception) }
  it { should have_one(:admission_phase_evaluation).dependent(:destroy) }
  it { should have_one(:admission_phase_result).dependent(:destroy) }
  it { should have_one(:admission_ranking_result).dependent(:destroy) }
  it { should have_many(:fields).dependent(:delete_all) }
  it { should belong_to(:form_template).required(true) }

  before(:all) do
    @destroy_later = []
    @form_template = FactoryBot.create(:form_template)
  end
  after(:all) do
    @form_template.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:filled_form) do
    Admissions::FilledForm.new(
      form_template: @form_template,
      is_filled: false
    )
  end
  subject { filled_form }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:form_template) }
  end
  describe "Methods" do
    describe "#erase_non_filled_file_fields" do
      # form_field_id faz o nested attributes instanciar um FilledFormField com form_field nil.
      # Antes da correção, field.form_field.is_file_field? estourava NoMethodError e a view devolvia 500 em vez da mensagem de validação.
      it "não estoura quando um field não tem form_field associado" do
        filled_form.fields << Admissions::FilledFormField.new(form_field: nil)
        expect { filled_form.erase_non_filled_file_fields }.not_to raise_error
      end

      it "continua tratando normalmente os fields com form_field presente" do
        @destroy_later << file_field = FactoryBot.create(
          :form_field, form_template: @form_template,
          field_type: Admissions::FormField::FILE
        )
        unfilled = Admissions::FilledFormField.new(form_field: file_field, file: "algo")
        filled_form.fields << unfilled
        filled_form.erase_non_filled_file_fields
        expect(unfilled.file).to be_blank
      end
    end
  end

  describe "nested attributes for fields" do
    # Antes da correção, uma entrada de fields_attributes sem id e sem form_field_id vira um FilledFormField inválido (form_field obrigatório)
    # e o save! falha inteiro por causa de um campo que o usuário nunca preencheu de propósito
    it "ignora entradas de fields_attributes sem id e sem form_field_id" do
      filled_form.save!
      filled_form.assign_attributes(
        fields_attributes: { "0" => { "file_" => { "base64_contents" => "", "filename" => "camera.jpg" } } }
      )
      expect(filled_form.fields).to be_empty
      expect { filled_form.save! }.not_to raise_error
    end

    it "continua aceitando entradas legítimas, com form_field_id presente" do
      @destroy_later << form_field = FactoryBot.create(
        :form_field, form_template: @form_template, field_type: Admissions::FormField::STRING
      )
      filled_form.save!
      filled_form.assign_attributes(
        fields_attributes: { "0" => { "form_field_id" => form_field.id, "value" => "x" } }
      )
      expect(filled_form.fields.size).to eq(1)
      filled_form.save!
      expect(filled_form.fields.reload.first.value).to eq("x")
    end
  end
  # Os exemplos acima ficaram vazios: `file: "algo"` nao popula o uploader (o
  # CarrierWave le a String como identificador de cache e descarta), e a carga
  # `{"file_" => ...}` nao chega ao modelo em producao -- o permit do controller
  # conhece `file`, nao `file_`. Os tres abaixo cobrem, com controle, o que
  # aqueles descrevem, e mais o ramo que nenhum exemplo executava.
  describe "#erase_non_filled_file_fields, com arquivo de verdade" do
    def anexo
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec", "fixtures", "user.png"), "image/png"
      )
    end

    let(:file_field) do
      @destroy_later << FactoryBot.create(
        :form_field, form_template: @form_template,
        field_type: Admissions::FormField::FILE
      )
      @destroy_later.last
    end

    it "descarta o arquivo do campo que ainda nao foi gravado" do
      novo = Admissions::FilledFormField.new(form_field: file_field)
      novo.file = anexo
      filled_form.fields << novo
      # Sem esta precondicao a assercao final valeria a toa, que e o que
      # acontecia com `file: "algo"`.
      expect(novo.file).to be_present

      filled_form.erase_non_filled_file_fields

      expect(novo.file).to be_blank
    end

    it "repoe do banco o arquivo do campo ja gravado" do
      filled_form.save!
      gravado = Admissions::FilledFormField.new(
        filled_form: filled_form, form_field: file_field
      )
      gravado.file = anexo
      gravado.save!
      filled_form.fields.reload
      alvo = filled_form.fields.first
      alvo.file = nil
      expect(alvo.file).to be_blank

      filled_form.erase_non_filled_file_fields

      # E este ramo que faz o aviso "reanexe os arquivos" ser verdadeiro: a
      # submissao invalida nao pode levar embora o que ja estava guardado.
      expect(alvo.file).to be_present
      expect(alvo.file.file.filename).to eq "user.png"
    end
  end

  describe "nested attributes: a entrada fantasma como ela chega de verdade" do
    # O permit filtra `file_`, entao o que sobra da #677 e uma entrada vazia sob
    # o indice do campo de foto. Sem o reject_if ela vira um FilledFormField sem
    # form_field, que e invalido e derruba o update inteiro.
    it "ignora a entrada vazia que sobra do campo fantasma" do
      filled_form.save!

      filled_form.assign_attributes(fields_attributes: { "0" => {} })

      expect(filled_form.fields).to be_empty
      expect { filled_form.save! }.not_to raise_error
    end
  end

  describe "campo orfao, sem form_field associado" do
    # O reject_if impede o orfao de nascer pelo caminho dos parametros, mas a
    # guarda que o PR acrescentou em erase_non_filled_file_fields e parcial:
    # add_error (filled_form_field.rb:283) le form_field.field_type sem guarda, e
    # that_either_value_or_file_is_filled o alcanca antes, no mesmo caminho de
    # render que a #677 percorre.
    it "nao estoura ao validar" do
      filled_form.fields << Admissions::FilledFormField.new(
        form_field: nil, value: "a", list: "b"
      )

      expect { filled_form.valid? }.not_to raise_error
    end
  end
  # Métodos: filled_form_consolidate_spec.rb.
end

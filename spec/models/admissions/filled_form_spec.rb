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
  # Métodos: filled_form_consolidate_spec.rb.
end

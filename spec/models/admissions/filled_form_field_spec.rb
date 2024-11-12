# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"


RSpec.describe Admissions::FilledFormField, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:filled_form).required(true) }
  it { should belong_to(:form_field).required(true) }
  it { should have_many(:scholarities).dependent(:delete_all) }

  before(:all) do
    @destroy_later = []
    @form_template = FactoryBot.create(:form_template)
    @filled_form = FactoryBot.create(:filled_form, form_template: @form_template)
    @form_field = FactoryBot.create(:form_field, form_template: @form_template)
  end
  after(:all) do
    @filled_form.delete
    @form_field.delete
    @form_template.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:filled_form) do
    Admissions::FilledFormField.new(
      value: "1",
      filled_form: @filled_form,
      form_field: @form_field
    )
  end
  subject { filled_form }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:filled_form) }
    it { should validate_presence_of(:form_field) }
    describe "that_either_value_or_file_is_filled" do
      it "should be valid when no values are filled" do
        @form_field.configuration = '{"required": false}'
        filled_form.value = nil
        filled_form.file = nil
        filled_form.list = nil
        expect(filled_form).to be_valid
      end
      it "should be valid when only one value is filled" do
        filled_form.value = "1"
        filled_form.file = nil
        filled_form.list = nil
        expect(filled_form).to be_valid
      end
      it "should have error when more than one value is filled" do
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form.value = "1"
        filled_form.file = nil
        filled_form.list = [1, 2]
        expect(filled_form).to have_field_error(:multiple_filling).on :value
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form.list = nil
      end
      it "should have error when more than one value is filled and attribute type is different" do
        @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
        filled_form.value = "1"
        filled_form.file = nil
        filled_form.list = [1, 2]
        expect(filled_form).to have_field_error(:multiple_filling).on :list
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form.list = nil
      end
    end
    describe "that_value_follows_configuration_rules" do
      before(:each) do
        filled_form.assign_attributes(value: nil, list: nil, file: nil)
      end
      describe "string fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::STRING
          @form_field.configuration = '{"required": false}'
          filled_form.value = nil
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::STRING
          @form_field.configuration = '{"required": true}'
          filled_form.value = "1"
          expect(filled_form).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::STRING
          @form_field.configuration = '{"required": true}'
          filled_form.value = nil
          expect(filled_form).to have_field_error(:blank).on :value
        end
      end
      describe "select fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::SELECT
          @form_field.configuration = '{"required": false, "values": "[1, 2]"}'
          filled_form.value = nil
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::SELECT
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form.value = "1"
          expect(filled_form).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::SELECT
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form.value = nil
          expect(filled_form).to have_field_error(:blank).on :value
        end
      end
      describe "radio fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::RADIO
          @form_field.configuration = '{"required": false, "values": "[1, 2]"}'
          filled_form.value = nil
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::RADIO
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form.value = "1"
          expect(filled_form).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::RADIO
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form.value = nil
          expect(filled_form).to have_field_error(:blank).on :value
        end
      end
      describe "collection_checkbox fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": false, "values": "[1, 2]"}'
          filled_form.list = nil
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form.list = ["1", "2"]
          expect(filled_form).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form.list = nil
          expect(filled_form).to have_field_error(:blank).on :list
        end
        it "valid when selection count >= minselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "minselection": 2}'
          filled_form.list = ["1", "2"]
          expect(filled_form).to be_valid
        end
        it "invalid when selection < minselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "minselection": 2}'
          filled_form.list = ["1"]
          expect(filled_form).to have_field_error(:minselection).on(:list).with_parameters(count: 2)
        end
        it "valid when selection count <= maxselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "maxselection": 2}'
          filled_form.list = ["1", "2"]
          expect(filled_form).to be_valid
        end
        it "invalid when selection > maxselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "maxselection": 2}'
          filled_form.list = ["1", "2", "3"]
          expect(filled_form).to have_field_error(:maxselection).on(:list).with_parameters(count: 2)
        end
      end
      describe "text fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false}'
          filled_form.value = nil
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true}'
          filled_form.value = "1"
          expect(filled_form).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true}'
          filled_form.value = nil
          expect(filled_form).to have_field_error(:blank).on :value
        end
      end
      describe "city fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false, "state_required": false, "country_required": false}'
          filled_form.value = nil
          expect(filled_form).to be_valid
        end
        it "valid when it only contains country and state, but city is not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false, "state_required": true, "country_required": true}'
          filled_form.value = " <$> RJ <$> Brasil"
          expect(filled_form).to be_valid
        end
        it "valid when it only contains country, but city and state are not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false, "state_required": false, "country_required": true}'
          filled_form.value = " <$>  <$> Brasil"
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form.value = "Niteroi <$> RJ <$> Brasil"
          expect(filled_form).to be_valid
        end
        it "invalid when city is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form.value = " <$> RJ <$> Brasil"
          expect(filled_form).to have_field_error(:city_blank).on :value
        end
        it "invalid when state is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form.value = "Niteroi <$>  <$> Brasil"
          expect(filled_form).to have_field_error(:state_blank).on :value
        end
        it "invalid when country is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form.value = "Niteroi <$> RJ <$> "
          expect(filled_form).to have_field_error(:country_blank).on :value
        end
      end
      describe "residency fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": false, "number_required": false}'
          filled_form.value = nil
          expect(filled_form).to be_valid
        end
        it "valid when it only contains number, but street is not required" do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": false, "number_required": true}'
          filled_form.value = " <$> 1"
          expect(filled_form).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": true, "number_required": true}'
          filled_form.value = "Rua X <$> 1"
          expect(filled_form).to be_valid
        end
        it "invalid when street is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": true, "number_required": true}'
          filled_form.value = " <$> 1"
          expect(filled_form).to have_field_error(:street_blank).on :value
        end
        it "invalid when number is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": true, "number_required": true}'
          filled_form.value = "Rua X <$> "
          expect(filled_form).to have_field_error(:number_blank).on :value
        end
      end
      describe "number fields should be" do
        it "valid when they are integers" do
          @form_field.field_type = Admissions::FormField::NUMBER
          filled_form.value = "1"
          expect(filled_form).to be_valid
        end
        it "valid when they are floats" do
          @form_field.field_type = Admissions::FormField::NUMBER
          filled_form.value = "1.1"
          expect(filled_form).to be_valid
        end
        it "invalid when filled with elements that are not numbers" do
          @form_field.field_type = Admissions::FormField::NUMBER
          filled_form.value = "aaa"
          expect(filled_form).to have_field_error(:invalid_number).on :value
        end
      end
      describe "date fields should be" do
        it "valid when they have date formats" do
          @form_field.field_type = Admissions::FormField::DATE
          filled_form.value = "11/11/2024"
          expect(filled_form).to be_valid
        end
        it "invalid when filled with elements that are not dates" do
          @form_field.field_type = Admissions::FormField::DATE
          filled_form.value = "aaa"
          expect(filled_form).to have_field_error(:invalid_date).on :value
        end
        it "invalid when filled with dates that are not in the %d/%m/%Y format" do
          @form_field.field_type = Admissions::FormField::DATE
          filled_form.value = "01/30/2024"
          expect(filled_form).to have_field_error(:invalid_date).on :value
        end
      end
      describe "student fields" do
        describe "special_city should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": false, "state_required": false, "country_required": false}'
            filled_form.value = nil
            expect(filled_form).to be_valid
          end
          it "valid when it only contains country and state, but city is not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": false, "state_required": true, "country_required": true}'
            filled_form.value = " <$> RJ <$> Brasil"
            expect(filled_form).to be_valid
          end
          it "valid when it only contains country, but city and state are not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": false, "state_required": false, "country_required": true}'
            filled_form.value = " <$>  <$> Brasil"
            expect(filled_form).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = "Niteroi <$> RJ <$> Brasil"
            expect(filled_form).to be_valid
          end
          it "invalid when city is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = " <$> RJ <$> Brasil"
            expect(filled_form).to have_field_error(:city_blank).on :value
          end
          it "invalid when state is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = "Niteroi <$>  <$> Brasil"
            expect(filled_form).to have_field_error(:state_blank).on :value
          end
          it "invalid when country is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = "Niteroi <$> RJ <$> "
            expect(filled_form).to have_field_error(:country_blank).on :value
          end
        end
        describe "special_birth_city should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": false, "state_required": false, "country_required": false}'
            filled_form.value = nil
            expect(filled_form).to be_valid
          end
          it "valid when it only contains country and state, but city is not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": false, "state_required": true, "country_required": true}'
            filled_form.value = " <$> RJ <$> Brasil"
            expect(filled_form).to be_valid
          end
          it "valid when it only contains country, but city and state are not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": false, "state_required": false, "country_required": true}'
            filled_form.value = " <$>  <$> Brasil"
            expect(filled_form).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = "Niteroi <$> RJ <$> Brasil"
            expect(filled_form).to be_valid
          end
          it "invalid when city is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = " <$> RJ <$> Brasil"
            expect(filled_form).to have_field_error(:city_blank).on :value
          end
          it "invalid when state is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = "Niteroi <$>  <$> Brasil"
            expect(filled_form).to have_field_error(:state_blank).on :value
          end
          it "invalid when country is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form.value = "Niteroi <$> RJ <$> "
            expect(filled_form).to have_field_error(:country_blank).on :value
          end
        end
        describe "special_address should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": false, "number_required": false}'
            filled_form.value = nil
            expect(filled_form).to be_valid
          end
          it "valid when it only contains number, but street is not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": false, "number_required": true}'
            filled_form.value = " <$> 1"
            expect(filled_form).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": true, "number_required": true}'
            filled_form.value = "Rua X <$> 1"
            expect(filled_form).to be_valid
          end
          it "invalid when street is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": true, "number_required": true}'
            filled_form.value = " <$> 1"
            expect(filled_form).to have_field_error(:street_blank).on :value
          end
          it "invalid when number is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": true, "number_required": true}'
            filled_form.value = "Rua X <$> "
            expect(filled_form).to have_field_error(:number_blank).on :value
          end
        end
        describe "birthdate should be" do
          it "valid when they have date formats" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "birthdate"}'
            filled_form.value = "11/11/2024"
            expect(filled_form).to be_valid
          end
          it "invalid when filled with elements that are not dates" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "birthdate"}'
            filled_form.value = "aaa"
            expect(filled_form).to have_field_error(:invalid_date).on :value
          end
          it "invalid when filled with dates that are not in the %d/%m/%Y format" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "birthdate"}'
            filled_form.value = "01/30/2024"
            expect(filled_form).to have_field_error(:invalid_date).on :value
          end
        end
        describe "identity_expedition_date should be" do
          it "valid when they have date formats" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "identity_expedition_date"}'
            filled_form.value = "11/11/2024"
            expect(filled_form).to be_valid
          end
          it "invalid when filled with elements that are not dates" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "identity_expedition_date"}'
            filled_form.value = "aaa"
            expect(filled_form).to have_field_error(:invalid_date).on :value
          end
          it "invalid when filled with dates that are not in the %d/%m/%Y format" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "identity_expedition_date"}'
            filled_form.value = "01/30/2024"
            expect(filled_form).to have_field_error(:invalid_date).on :value
          end
        end
        describe "other types of fields should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "name", "required": false}'
            filled_form.value = nil
            expect(filled_form).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "name", "required": true}'
            filled_form.value = "1"
            expect(filled_form).to be_valid
          end
          it "invalid when null and required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "name", "required": true}'
            filled_form.value = nil
            expect(filled_form).to have_field_error(:blank).on :value
          end
        end
      end
      # ToDo: validate file field (Admissions::FormField::FILE)
      # - size_of_file
      # - validate_file_field
      # - Admissions::FormField::STUDENT_FIELD with field == "photo"
    end
  end

  describe "Methods" do
    # ToDo: test set_default_values
    # ToDo: test to_label
    # ToDo: test to_text
    # ToDo: test simple_value
    # ToDo: test set_model_field
    # ToDo: test get_type
    # ToDo: test convert_value
    # ToDo: test convert_string
    # ToDo: test convert_number
    # ToDo: test convert_date
  end
end

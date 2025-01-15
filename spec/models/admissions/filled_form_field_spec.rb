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
  let(:filled_form_field) do
    Admissions::FilledFormField.new(
      value: "1",
      filled_form: @filled_form,
      form_field: @form_field
    )
  end
  before(:each) do
    @form_field.field_type = Admissions::FormField::STRING
    filled_form_field.value = "1"
    filled_form_field.filled_form = @filled_form
    filled_form_field.form_field = @form_field

  end
  subject { filled_form_field }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:filled_form) }
    it { should validate_presence_of(:form_field) }
    describe "that_either_value_or_file_is_filled" do
      it "should be valid when no values are filled" do
        @form_field.configuration = '{"required": false}'
        filled_form_field.value = nil
        filled_form_field.file = nil
        filled_form_field.list = nil
        expect(filled_form_field).to be_valid
      end
      it "should be valid when only one value is filled" do
        filled_form_field.value = "1"
        filled_form_field.file = nil
        filled_form_field.list = nil
        expect(filled_form_field).to be_valid
      end
      it "should have error when more than one value is filled" do
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form_field.value = "1"
        filled_form_field.file = nil
        filled_form_field.list = [1, 2]
        expect(filled_form_field).to have_field_error(:multiple_filling).on :value
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form_field.list = nil
      end
      it "should have error when more than one value is filled and attribute type is different" do
        @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
        filled_form_field.value = "1"
        filled_form_field.file = nil
        filled_form_field.list = [1, 2]
        expect(filled_form_field).to have_field_error(:multiple_filling).on :list
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form_field.list = nil
      end
    end
    describe "that_value_follows_configuration_rules" do
      before(:each) do
        filled_form_field.assign_attributes(value: nil, list: nil, file: nil)
      end
      describe "string fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::STRING
          @form_field.configuration = '{"required": false}'
          filled_form_field.value = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::STRING
          @form_field.configuration = '{"required": true}'
          filled_form_field.value = "1"
          expect(filled_form_field).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::STRING
          @form_field.configuration = '{"required": true}'
          filled_form_field.value = nil
          expect(filled_form_field).to have_field_error(:blank).on :value
        end
      end
      describe "select fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::SELECT
          @form_field.configuration = '{"required": false, "values": "[1, 2]"}'
          filled_form_field.value = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::SELECT
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form_field.value = "1"
          expect(filled_form_field).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::SELECT
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form_field.value = nil
          expect(filled_form_field).to have_field_error(:blank).on :value
        end
      end
      describe "radio fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::RADIO
          @form_field.configuration = '{"required": false, "values": "[1, 2]"}'
          filled_form_field.value = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::RADIO
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form_field.value = "1"
          expect(filled_form_field).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::RADIO
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form_field.value = nil
          expect(filled_form_field).to have_field_error(:blank).on :value
        end
      end
      describe "collection_checkbox fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": false, "values": "[1, 2]"}'
          filled_form_field.list = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form_field.list = ["1", "2"]
          expect(filled_form_field).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]"}'
          filled_form_field.list = nil
          expect(filled_form_field).to have_field_error(:blank).on :list
        end
        it "valid when selection count >= minselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "minselection": 2}'
          filled_form_field.list = ["1", "2"]
          expect(filled_form_field).to be_valid
        end
        it "invalid when selection < minselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "minselection": 2}'
          filled_form_field.list = ["1"]
          expect(filled_form_field).to have_field_error(:minselection).on(:list).with_parameters(count: 2)
        end
        it "valid when selection count <= maxselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "maxselection": 2}'
          filled_form_field.list = ["1", "2"]
          expect(filled_form_field).to be_valid
        end
        it "invalid when selection > maxselection" do
          @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
          @form_field.configuration = '{"required": true, "values": "[1, 2]", "maxselection": 2}'
          filled_form_field.list = ["1", "2", "3"]
          expect(filled_form_field).to have_field_error(:maxselection).on(:list).with_parameters(count: 2)
        end
      end
      describe "text fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false}'
          filled_form_field.value = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true}'
          filled_form_field.value = "1"
          expect(filled_form_field).to be_valid
        end
        it "invalid when null and required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true}'
          filled_form_field.value = nil
          expect(filled_form_field).to have_field_error(:blank).on :value
        end
      end
      describe "city fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false, "state_required": false, "country_required": false}'
          filled_form_field.value = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when it only contains country and state, but city is not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false, "state_required": true, "country_required": true}'
          filled_form_field.value = " <$> RJ <$> Brasil"
          expect(filled_form_field).to be_valid
        end
        it "valid when it only contains country, but city and state are not required" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": false, "state_required": false, "country_required": true}'
          filled_form_field.value = " <$>  <$> Brasil"
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form_field.value = "Niteroi <$> RJ <$> Brasil"
          expect(filled_form_field).to be_valid
        end
        it "invalid when city is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form_field.value = " <$> RJ <$> Brasil"
          expect(filled_form_field).to have_field_error(:city_blank).on :value
        end
        it "invalid when state is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form_field.value = "Niteroi <$>  <$> Brasil"
          expect(filled_form_field).to have_field_error(:state_blank).on :value
        end
        it "invalid when country is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::CITY
          @form_field.configuration = '{"required": true, "state_required": true, "country_required": true}'
          filled_form_field.value = "Niteroi <$> RJ <$> "
          expect(filled_form_field).to have_field_error(:country_blank).on :value
        end
      end
      describe "residency fields should be" do
        it "valid when null and not required" do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": false, "number_required": false}'
          filled_form_field.value = nil
          expect(filled_form_field).to be_valid
        end
        it "valid when it only contains number, but street is not required" do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": false, "number_required": true}'
          filled_form_field.value = " <$> 1"
          expect(filled_form_field).to be_valid
        end
        it "valid when filled" do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": true, "number_required": true}'
          filled_form_field.value = "Rua X <$> 1"
          expect(filled_form_field).to be_valid
        end
        it "invalid when street is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": true, "number_required": true}'
          filled_form_field.value = " <$> 1"
          expect(filled_form_field).to have_field_error(:street_blank).on :value
        end
        it "invalid when number is blank, but it is required " do
          @form_field.field_type = Admissions::FormField::RESIDENCY
          @form_field.configuration = '{"required": true, "number_required": true}'
          filled_form_field.value = "Rua X <$> "
          expect(filled_form_field).to have_field_error(:number_blank).on :value
        end
      end
      describe "number fields should be" do
        it "valid when they are integers" do
          @form_field.field_type = Admissions::FormField::NUMBER
          filled_form_field.value = "1"
          expect(filled_form_field).to be_valid
        end
        it "valid when they are floats" do
          @form_field.field_type = Admissions::FormField::NUMBER
          filled_form_field.value = "1.1"
          expect(filled_form_field).to be_valid
        end
        it "invalid when filled with elements that are not numbers" do
          @form_field.field_type = Admissions::FormField::NUMBER
          filled_form_field.value = "aaa"
          expect(filled_form_field).to have_field_error(:invalid_number).on :value
        end
      end
      describe "date fields should be" do
        it "valid when they have date formats" do
          @form_field.field_type = Admissions::FormField::DATE
          filled_form_field.value = "11/11/2024"
          expect(filled_form_field).to be_valid
        end
        it "invalid when filled with elements that are not dates" do
          @form_field.field_type = Admissions::FormField::DATE
          filled_form_field.value = "aaa"
          expect(filled_form_field).to have_field_error(:invalid_date).on :value
        end
        it "invalid when filled with dates that are not in the %d/%m/%Y format" do
          @form_field.field_type = Admissions::FormField::DATE
          filled_form_field.value = "01/30/2024"
          expect(filled_form_field).to have_field_error(:invalid_date).on :value
        end
      end
      describe "student fields" do
        describe "special_city should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": false, "state_required": false, "country_required": false}'
            filled_form_field.value = nil
            expect(filled_form_field).to be_valid
          end
          it "valid when it only contains country and state, but city is not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": false, "state_required": true, "country_required": true}'
            filled_form_field.value = " <$> RJ <$> Brasil"
            expect(filled_form_field).to be_valid
          end
          it "valid when it only contains country, but city and state are not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": false, "state_required": false, "country_required": true}'
            filled_form_field.value = " <$>  <$> Brasil"
            expect(filled_form_field).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = "Niteroi <$> RJ <$> Brasil"
            expect(filled_form_field).to be_valid
          end
          it "invalid when city is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = " <$> RJ <$> Brasil"
            expect(filled_form_field).to have_field_error(:city_blank).on :value
          end
          it "invalid when state is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = "Niteroi <$>  <$> Brasil"
            expect(filled_form_field).to have_field_error(:state_blank).on :value
          end
          it "invalid when country is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = "Niteroi <$> RJ <$> "
            expect(filled_form_field).to have_field_error(:country_blank).on :value
          end
        end
        describe "special_birth_city should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": false, "state_required": false, "country_required": false}'
            filled_form_field.value = nil
            expect(filled_form_field).to be_valid
          end
          it "valid when it only contains country and state, but city is not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": false, "state_required": true, "country_required": true}'
            filled_form_field.value = " <$> RJ <$> Brasil"
            expect(filled_form_field).to be_valid
          end
          it "valid when it only contains country, but city and state are not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": false, "state_required": false, "country_required": true}'
            filled_form_field.value = " <$>  <$> Brasil"
            expect(filled_form_field).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = "Niteroi <$> RJ <$> Brasil"
            expect(filled_form_field).to be_valid
          end
          it "invalid when city is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = " <$> RJ <$> Brasil"
            expect(filled_form_field).to have_field_error(:city_blank).on :value
          end
          it "invalid when state is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = "Niteroi <$>  <$> Brasil"
            expect(filled_form_field).to have_field_error(:state_blank).on :value
          end
          it "invalid when country is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_birth_city", "required": true, "state_required": true, "country_required": true}'
            filled_form_field.value = "Niteroi <$> RJ <$> "
            expect(filled_form_field).to have_field_error(:country_blank).on :value
          end
        end
        describe "special_address should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": false, "number_required": false}'
            filled_form_field.value = nil
            expect(filled_form_field).to be_valid
          end
          it "valid when it only contains number, but street is not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": false, "number_required": true}'
            filled_form_field.value = " <$> 1"
            expect(filled_form_field).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": true, "number_required": true}'
            filled_form_field.value = "Rua X <$> 1"
            expect(filled_form_field).to be_valid
          end
          it "invalid when street is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": true, "number_required": true}'
            filled_form_field.value = " <$> 1"
            expect(filled_form_field).to have_field_error(:street_blank).on :value
          end
          it "invalid when number is blank, but it is required " do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "special_address", "required": true, "number_required": true}'
            filled_form_field.value = "Rua X <$> "
            expect(filled_form_field).to have_field_error(:number_blank).on :value
          end
        end
        describe "birthdate should be" do
          it "valid when they have date formats" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "birthdate"}'
            filled_form_field.value = "11/11/2024"
            expect(filled_form_field).to be_valid
          end
          it "invalid when filled with elements that are not dates" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "birthdate"}'
            filled_form_field.value = "aaa"
            expect(filled_form_field).to have_field_error(:invalid_date).on :value
          end
          it "invalid when filled with dates that are not in the %d/%m/%Y format" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "birthdate"}'
            filled_form_field.value = "01/30/2024"
            expect(filled_form_field).to have_field_error(:invalid_date).on :value
          end
        end
        describe "identity_expedition_date should be" do
          it "valid when they have date formats" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "identity_expedition_date"}'
            filled_form_field.value = "11/11/2024"
            expect(filled_form_field).to be_valid
          end
          it "invalid when filled with elements that are not dates" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "identity_expedition_date"}'
            filled_form_field.value = "aaa"
            expect(filled_form_field).to have_field_error(:invalid_date).on :value
          end
          it "invalid when filled with dates that are not in the %d/%m/%Y format" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "identity_expedition_date"}'
            filled_form_field.value = "01/30/2024"
            expect(filled_form_field).to have_field_error(:invalid_date).on :value
          end
        end
        describe "other types of fields should be" do
          it "valid when null and not required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "name", "required": false}'
            filled_form_field.value = nil
            expect(filled_form_field).to be_valid
          end
          it "valid when filled" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "name", "required": true}'
            filled_form_field.value = "1"
            expect(filled_form_field).to be_valid
          end
          it "invalid when null and required" do
            @form_field.field_type = Admissions::FormField::STUDENT_FIELD
            @form_field.configuration = '{"field": "name", "required": true}'
            filled_form_field.value = nil
            expect(filled_form_field).to have_field_error(:blank).on :value
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
    describe "set_default_values" do
      it "should set the value as default if current value is nil and type is STRING" do
        @form_field.configuration = '{"default": "a"}'
        @form_field.field_type = Admissions::FormField::STRING
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("a")
      end
      it "should set the value as default if current value is nil, type is SELECT, and the value exists in values" do
        @form_field.configuration = '{"default": "a", "values": ["a", "b"]}'
        @form_field.field_type = Admissions::FormField::SELECT
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("a")
      end
      it "should not set the value as default if current value is nil, type is SELECT, and the value does not exist in values" do
        @form_field.configuration = '{"default": "a", "values": ["c", "b"]}'
        @form_field.field_type = Admissions::FormField::SELECT
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq(nil)
      end
      it "should set the list as default if current list is nil, and type is COLLECTION_CHECKBOX" do
        @form_field.configuration = '{"default_values": ["a", "b"]}'
        @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
        filled_form_field.list = nil
        filled_form_field.set_default_values
        expect(filled_form_field.list).to eq(["a", "b"])
      end
      it "should set the value as default if current value is nil and type is RADIO" do
        @form_field.configuration = '{"default": "a", "values": {"a": "a"}}'
        @form_field.field_type = Admissions::FormField::RADIO
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("a")
      end
      it "should set the value as 1 if default_check is true and current value is nil and type is SINGLE_CHECKBOX" do
        @form_field.configuration = '{"default_check": true}'
        @form_field.field_type = Admissions::FormField::SINGLE_CHECKBOX
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("1")
      end
      it "should set the value as 0 if default_check is true and current value is nil and type is SINGLE_CHECKBOX" do
        @form_field.configuration = '{"default_check": false}'
        @form_field.field_type = Admissions::FormField::SINGLE_CHECKBOX
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("0")
      end
      it "should set the value as default if current value is nil and type is TEXT" do
        @form_field.configuration = '{"default": "a"}'
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("a")
      end
      it "should set the value as default if current value is nil and type is NUMBER" do
        @form_field.configuration = '{"default": "1"}'
        @form_field.field_type = Admissions::FormField::NUMBER
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("1")
      end
      it "should set the value as default if current value is nil and type is DATE" do
        @form_field.configuration = '{"default": "2024/01/01"}'
        @form_field.field_type = Admissions::FormField::DATE
        filled_form_field.value = nil
        filled_form_field.set_default_values
        expect(filled_form_field.value).to eq("2024/01/01")
      end
    end
    describe "to_label" do
      it "should return '-' if form_field is blank" do
        filled_form_field.form_field = nil
        expect(filled_form_field.to_label).to eq("-")
      end
      it "should return 'field: -' if form_field name is 'field' and all values are blank" do
        filled_form_field.form_field.name = 'field'
        filled_form_field.file = nil
        filled_form_field.list = nil
        filled_form_field.value = nil
        expect(filled_form_field.to_label).to eq("field: -")
      end
      it "should return 'field: value' if form_field name is 'field' and it has a value" do
        filled_form_field.form_field.name = 'field'
        filled_form_field.file = nil
        filled_form_field.list = nil
        filled_form_field.value = "value"
        expect(filled_form_field.to_label).to eq("field: value")
      end
      it "should return 'field: [1, 2]' if form_field name is 'field' and it has a list" do
        filled_form_field.form_field.name = 'field'
        filled_form_field.file = nil
        filled_form_field.list = ["1", "2"]
        filled_form_field.value = nil
        expect(filled_form_field.to_label).to eq('field: ["1", "2"]')
      end
      # ToDo: filled file
    end
    describe "to_text" do
      it "should return - when form_field is blank" do
        filled_form_field.form_field = nil
        expect(filled_form_field.to_text).to eq("-")
      end
      it "should invoke function when custom method is defined" do
        @form_field.field_type = Admissions::FormField::NUMBER
        filled_form_field.value = "2"
        expect(filled_form_field.to_text(
          custom: {
            Admissions::FormField::NUMBER => -> (filled_fielf, form_field) {
              "1"
            }
          }
        )).to eq("1")
      end
      it "should override type when field_type is provided" do
        @form_field.field_type = Admissions::FormField::STRING
        filled_form_field.value = "2"
        expect(filled_form_field.to_text(
          field_type: Admissions::FormField::NUMBER,
          custom: {
            Admissions::FormField::NUMBER => -> (filled_fielf, form_field) {
              "1"
            }
          }
        )).to eq("1")
      end
      it "should show all checkbox values when type is COLLECTION_CHECKBOX" do
        @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
        @form_field.configuration = '{"values": ["a", "b", "c"]}'
        filled_form_field.list = ["b", "c"]
        expect(filled_form_field.to_text).to eq("b, c")
      end
      it "should return - when type is COLLECTION_CHECKBOX and list is blank" do
        @form_field.field_type = Admissions::FormField::COLLECTION_CHECKBOX
        @form_field.configuration = '{"values": ["a", "b", "c"]}'
        filled_form_field.list = []
        expect(filled_form_field.to_text).to eq("-")
      end
      it "should return - when type is SELECT and value is blank" do
        @form_field.field_type = Admissions::FormField::SELECT
        @form_field.configuration = '{"values": ["a", "b", "c"]}'
        filled_form_field.value = nil
        expect(filled_form_field.to_text).to eq("-")
      end
      it "should return value when type is SELECT and value is filled" do
        @form_field.field_type = Admissions::FormField::SELECT
        @form_field.configuration = '{"values": ["a", "b", "c"]}'
        filled_form_field.value = "a"
        expect(filled_form_field.to_text).to eq("a")
      end
      it "should return - when type is RADIO and value is blank" do
        @form_field.field_type = Admissions::FormField::RADIO
        @form_field.configuration = '{"values": ["a", "b", "c"]}'
        filled_form_field.value = nil
        expect(filled_form_field.to_text).to eq("-")
      end
      it "should return value when type is RADIO and value is filled" do
        @form_field.field_type = Admissions::FormField::RADIO
        @form_field.configuration = '{"values": ["a", "b", "c"]}'
        filled_form_field.value = "a"
        expect(filled_form_field.to_text).to eq("a")
      end
      it "should return city when type is CITY and value is filled" do
        @form_field.field_type = Admissions::FormField::CITY
        filled_form_field.value = "Niterói <$> RJ <$> Brasil"
        expect(filled_form_field.to_text).to eq("Niterói, RJ, Brasil")
      end
      it "should return city when type is STUDENT_FIELD and field is special_city" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "special_city"}'
        filled_form_field.value = "Niterói <$> RJ <$> Brasil"
        expect(filled_form_field.to_text).to eq("Niterói, RJ, Brasil")
      end
      it "should return city when type is STUDENT_FIELD and field is special_birth_city" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "special_birth_city"}'
        filled_form_field.value = "Niterói <$> RJ <$> Brasil"
        expect(filled_form_field.to_text).to eq("Niterói, RJ, Brasil")
      end
      it "should return residency when type is RESIDENCY and value is filled" do
        @form_field.field_type = Admissions::FormField::RESIDENCY
        filled_form_field.value = "Rua abc <$> 123"
        expect(filled_form_field.to_text).to eq("Rua abc, 123")
      end
      it "should return residency when type is STUDENT_FIELD and field is special_address" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "special_address"}'
        filled_form_field.value = "Rua abc <$> 123"
        expect(filled_form_field.to_text).to eq("Rua abc, 123")
      end
      it "should return value when type is STUDENT_FIELD and field is not special" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "name"}'
        filled_form_field.value = "Ana"
        expect(filled_form_field.to_text).to eq("Ana")
      end
      it "should return value for other types" do
        @form_field.field_type = Admissions::FormField::TEXT
        filled_form_field.value = "Ana"
        expect(filled_form_field.to_text).to eq("Ana")
      end
      # ToDo: Admissions::FormField::FILE
      # ToDo: Admissions::FormField::STUDENT_FIELD, field=photo
      # ToDo: Admissions::FormField::SCHOLARITY
      # ToDo: Admissions::FormField::STUDENT_FIELD, field=special_majors
    end
    describe "simple_value" do
      it "should return list if list is present" do
        filled_form_field.file = nil
        filled_form_field.list = ["1", "2"]
        filled_form_field.value = nil
        expect(filled_form_field.simple_value).to eq(["1", "2"])
      end
      it "should return value if value is present" do
        filled_form_field.file = nil
        filled_form_field.list = nil
        filled_form_field.value = "1"
        expect(filled_form_field.simple_value).to eq("1")
      end
      # ToDo: File
    end
    describe "get_type" do
      it "should return number when the form_type is NUMBER" do
        @form_field.field_type = Admissions::FormField::NUMBER
        expect(filled_form_field.get_type).to eq("number")
      end
      it "should return date when the form_type is DATE" do
        @form_field.field_type = Admissions::FormField::DATE
        expect(filled_form_field.get_type).to eq("date")
      end
      it "should return date when the form_type is STUDENT_FIELD and field is birthdate" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "birthdate"}'
        expect(filled_form_field.get_type).to eq("date")
      end
      it "should return date when the form_type is STUDENT_FIELD and field is identity_expedition_date" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "identity_expedition_date"}'
        expect(filled_form_field.get_type).to eq("date")
      end
      it "should return string when the form_type is STUDENT_FIELD and field is anything else" do
        @form_field.field_type = Admissions::FormField::STUDENT_FIELD
        @form_field.configuration = '{"field": "name"}'
        expect(filled_form_field.get_type).to eq("string")
      end
      it "should return number when the form_type is CODE and code_type is not defined" do
        @form_field.field_type = Admissions::FormField::CODE
        @form_field.configuration = '{}'
        expect(filled_form_field.get_type).to eq("number")
      end
      it "should return code_type when the form_type is CODE and code_type is defined" do
        @form_field.field_type = Admissions::FormField::CODE
        @form_field.configuration = '{"code_type": "string"}'
        expect(filled_form_field.get_type).to eq("string")
      end
      it "should return string when the form_type is anything else" do
        @form_field.field_type = Admissions::FormField::TEXT
        expect(filled_form_field.get_type).to eq("string")
      end
    end
    describe "convert_value" do
      it "should convert a string" do
        expect(Admissions::FilledFormField.convert_value(1, "string")).to eq("1")
      end
      it "should convert a number" do
        expect(Admissions::FilledFormField.convert_value("10.3", "number")).to eq(10.3)
      end
      it "should convert a date" do
        expect(Admissions::FilledFormField.convert_value("15/01/2024", "date")).to eq(Date.new(2024, 1, 15))
      end
      it "should not convert unknown types" do
        expect(Admissions::FilledFormField.convert_value("1", "other")).to eq("1")
      end
    end
    describe "convert_string" do
      it "should convert a string" do
        expect(Admissions::FilledFormField.convert_string(1)).to eq("1")
      end
    end
    describe "convert_number" do
      it "should convert a number" do
        expect(Admissions::FilledFormField.convert_number("10.3")).to eq(10.3)
      end
    end
    describe "convert_date" do
      it "should convert a date" do
        expect(Admissions::FilledFormField.convert_date("15/01/2024")).to eq(Date.new(2024, 1, 15))
      end
    end
    # ToDo: test set_model_field
  end
end

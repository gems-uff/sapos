# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"


RSpec.describe Admissions::FilledFormFieldScholarity, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:filled_form_field).required(true) }

  before(:all) do
    @destroy_later = []
    @form_template = FactoryBot.create(:form_template)
    @filled_form = FactoryBot.create(:filled_form, form_template: @form_template)
    @form_field = FactoryBot.create(
      :form_field, form_template: @form_template,
      field_type: Admissions::FormField::SCHOLARITY,
      configuration: '{"values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
    )
    @filled_form_field = FactoryBot.build(
      :filled_form_field, filled_form: @filled_form, form_field: @form_field
    )
    @filled_form_field_scholarity = @filled_form_field.scholarities.build(
      filled_form_field: @filled_form_field,
      level: 1,
      status: 1,
      institution: "UFF",
      course: "Computação",
      location: "Niteroi/RJ",
      grade: "9",
      grade_interval: "0..10",
      start_date: 5.years.ago,
      end_date: 1.year.ago
    )
    @filled_form_field_scholarity.filled_form_field = @filled_form_field
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
  let(:filled_form_field_scholarity) do
    @filled_form_field_scholarity.filled_form_field = @filled_form_field
    @filled_form_field_scholarity
  end
  subject { filled_form_field_scholarity }
  describe "Validations" do
    it { should be_valid }
    describe "that_value_follows_configuration_rules" do
      before(:each) do
        filled_form_field_scholarity.assign_attributes(
          level: 1,
          status: 1,
          institution: "UFF",
          course: "Computação",
          location: "Niteroi/RJ",
          grade: "9",
          grade_interval: "0..10",
          start_date: 5.years.ago,
          end_date: 1.year.ago
        )
      end
      it "should be valid when all values are filled" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        expect(filled_form_field_scholarity).to be_valid
        expect(@filled_form_field).to be_valid
      end
      it "should be valid when no values are required" do
        @form_field.configuration = '{"scholarity_level_required": false, "scholarity_status_required": false, "scholarity_institution_required": false, "scholarity_course_required": false, "scholarity_location_required": false, "scholarity_grade_required": false, "scholarity_grade_interval_required": false, "scholarity_start_date_required": false, "scholarity_end_date_required": false, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.assign_attributes(
          level: 1,
          status: nil,
          institution: nil,
          course: nil,
          location: nil,
          grade: nil,
          grade_interval: nil,
          start_date: nil,
          end_date: nil
        )
        expect(filled_form_field_scholarity).to be_valid
        expect(@filled_form_field).to be_valid
      end
      it "should have error when level is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.level = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Nível")
      end
      it "should have error when status is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.status = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Situação")
      end
      it "should have error when institution is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.institution = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Instituição")
      end
      it "should have error when course is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.course = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Curso")
      end
      it "should have error when location is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.location = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Cidade/Estado")
      end
      it "should have error when grade is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.grade = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "CR ou conceito obtido")
      end
      it "should have error when grade_interval is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.grade_interval = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Intervalo de CR ou conceito")
      end
      it "should have error when start_date is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.start_date = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Data de início")
      end
      it "should have error when end_date is required but blank" do
        @form_field.configuration = '{"scholarity_level_required": true, "scholarity_status_required": true, "scholarity_institution_required": true, "scholarity_course_required": true, "scholarity_location_required": true, "scholarity_grade_required": true, "scholarity_grade_interval_required": true, "scholarity_start_date_required": true, "scholarity_end_date_required": true, "values": ["Graduação", "Mestrado", "Doutorado"], "statuses": ["Completo", "Incompleto"]}'
        filled_form_field_scholarity.end_date = nil
        expect(@filled_form_field).not_to be_valid
        expect(@filled_form_field).to have_field_error(:scholarity_blank).on(:value).with_parameters(attr: "Data de término")
      end
    end
  end

  describe "Methods" do
    # O to_label monta o texto com um join, que chama to_s em cada item. Enquanto
    # Date#to_s estava sobrescrito globalmente, a data saia no formato brasileiro
    # de graca; sem o patch, sairia a forma ISO do Ruby. A suite executava estas
    # linhas e nao acusou nada, porque nada assertava o texto -- por isso os
    # exemplos abaixo olham a string inteira.
    describe "to_label" do
      # Sem persistir: to_label so le atributos, e assim os exemplos independem
      # das associacoes montadas no before(:all) acima.
      def scholarity(**attrs)
        Admissions::FilledFormFieldScholarity.new({
          level: "Mestrado", status: "Completo", institution: "UFF",
          course: "Computação", location: "Niteroi/RJ", grade: "9",
          start_date: Date.new(2018, 3, 1), end_date: Date.new(2021, 12, 31)
        }.merge(attrs))
      end

      it "formats the period in the brazilian format" do
        expect(scholarity.to_label).to eq(
          "Mestrado - Completo - UFF - Computação - Niteroi/RJ - 9 " \
          "(01/03/2018 - 31/12/2021)"
        )
      end

      it "formats a period with only the start date" do
        expect(scholarity(end_date: nil).to_label).to end_with("(01/03/2018)")
      end

      it "formats a period with only the end date" do
        expect(scholarity(start_date: nil).to_label).to end_with("(31/12/2021)")
      end

      it "omits the period when there is no date" do
        label = scholarity(start_date: nil, end_date: nil).to_label
        expect(label).to eq(
          "Mestrado - Completo - UFF - Computação - Niteroi/RJ - 9"
        )
        expect(label).not_to include("(")
      end

      it "keeps a date out of the ISO format that Ruby uses by default" do
        expect(scholarity.to_label).not_to include("2018-03-01")
      end

      it "translates level and status through the given maps" do
        label = scholarity(level: "2", status: "1").to_label(
          values: { "2" => "Doutorado" }, statuses: { "1" => "Incompleto" }
        )
        expect(label).to start_with("Doutorado - Incompleto - UFF")
      end

      it "skips the blank parts without leaving a dangling separator" do
        label = scholarity(location: nil, grade: nil).to_label
        expect(label).to eq(
          "Mestrado - Completo - UFF - Computação (01/03/2018 - 31/12/2021)"
        )
      end
    end
  end
end

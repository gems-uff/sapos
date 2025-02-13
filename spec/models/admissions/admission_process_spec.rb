# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionProcess, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:admission_applications).dependent(:restrict_with_exception) }
  it { should have_many(:phases).dependent(:restrict_with_exception) }
  it { should have_many(:rankings).dependent(:destroy) }

  it { should belong_to(:form_template).required(true) }
  it { should belong_to(:letter_template).required(false) }
  it { should belong_to(:level).required(false) }
  it { should belong_to(:enrollment_status).required(false) }

  before(:all) do
    @form_template = FactoryBot.create(:form_template)
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
    @form_template.delete
  end
  let(:admission_process) do
    Admissions::AdmissionProcess.new(
      name: "Mestrado 2024.1",
      year: 2024,
      semester: 1,
      start_date: Date.parse("2024/01/01"),
      end_date: Date.parse("2024/02/01"),
      edit_date: Date.parse("2024/02/15"),
      form_template: @form_template
    )
  end
  subject { admission_process }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:form_template) }
    it { should validate_numericality_of(:min_letters).is_greater_than(-1).only_integer.allow_nil }
    it { should validate_numericality_of(:max_letters).is_greater_than(-1).only_integer.allow_nil }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:year) }
    it { should validate_presence_of(:semester) }
    it { should validate_inclusion_of(:semester).in_array(YearSemester::SEMESTERS) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    describe "end_date" do
      context "should be valid when" do
        it "end_date is greater than start_date" do
          admission_process.end_date = admission_process.start_date + 1.month
          expect(admission_process).to have(0).errors_on :base
          admission_process.end_date = Date.parse("2024/02/01")
        end
      end
      context "should have error end_greater_than_start_date when" do
        it "start_date is greater than end_date" do
          admission_process.end_date = admission_process.start_date - 1.month
          expect(admission_process).to have_error(:end_greater_than_start_date).on :base
          admission_process.end_date = Date.parse("2024/02/01")
        end
      end
    end
    describe "letters" do
      context "should be valid when" do
        it "max_letters is nil" do
          admission_process.min_letters = 1
          admission_process.max_letters = nil
          expect(admission_process).to have(0).errors_on :base
          admission_process.min_letters = nil
        end
        it "max_letters is greater than min_letters" do
          admission_process.min_letters = 1
          admission_process.max_letters = 2
          expect(admission_process).to have(0).errors_on :base
          admission_process.min_letters = nil
          admission_process.max_letters = nil
        end
      end
      context "should have error max_greater_than_min_letters when" do
        it "min_letters is greater than max_greater_than_min_letters" do
          admission_process.min_letters = 2
          admission_process.max_letters = 1
          expect(admission_process).to have_error(:max_greater_than_min_letters).on :base
          admission_process.min_letters = nil
          admission_process.max_letters = nil
        end
      end
    end
    describe "simple_url" do
      context "should be valid when" do
        it "there are no other processes with the same simple_url in the same range" do
          admission_process.simple_url = "mestrado"
          admission_process.start_date = Date.parse("2024/01/01")
          admission_process.end_date = Date.today + 1.month
          # Date overlap, different simple url
          @destroy_later << FactoryBot.create(:admission_process,
            start_date: admission_process.start_date,
            end_date: admission_process.end_date,
            simple_url: "doutorado"
          )
          # Same simple url, different date
          @destroy_later << FactoryBot.create(:admission_process,
            start_date: admission_process.start_date - 3.months,
            end_date: admission_process.end_date - 2.months,
            simple_url: "mestrado"
          )
          expect(admission_process).to have(0).errors_on :simple_url
        end
        it "admission process was in the past" do
          admission_process.simple_url = "mestrado"
          admission_process.start_date = Date.parse("2024/01/01")
          admission_process.end_date = Date.parse("2024/02/01")
          # Date overlap, different simple url
          @destroy_later << FactoryBot.create(:admission_process,
            start_date: admission_process.start_date,
            end_date: admission_process.end_date,
            simple_url: "mestrado"
          )
          expect(admission_process).to have(0).errors_on :simple_url
        end

      end
      context "should have error simple_url_integer when" do
        it "it is a number" do
          admission_process.start_date = Date.parse("2024/01/01")
          admission_process.end_date = Date.today + 1.month
          admission_process.simple_url = "1"
          expect(admission_process).to have_error(:simple_url_integer).on :simple_url
        end
        it "it overlaps a date" do
          admission_process.simple_url = "mestrado"
          admission_process.start_date = Date.parse("2024/01/01")
          admission_process.end_date = Date.today + 1.month
          @destroy_later << FactoryBot.create(:admission_process,
            start_date: admission_process.start_date - 1.month,
            end_date: admission_process.end_date - 1.day,
            simple_url: "mestrado"
          )
          expect(admission_process).to have_error(:simple_url_collides_in_date_range).on :simple_url
        end
      end

    end
  end
  describe "Duplication" do
    # ToDo: initialize_dup
  end
  describe "Methods" do
    describe "max_edit_date" do
      it "should be end_date when edit_date is nil" do
        admission_process.edit_date = nil
        expect(admission_process.max_edit_date).to eq(admission_process.end_date)
      end
      it "should be edit_date when edit_date is filled" do
        admission_process.edit_date = Date.parse("2024/02/15")
        expect(admission_process.max_edit_date).to eq(Date.parse("2024/02/15"))
      end
    end
    describe "has_letters" do
      it "should be false when both min_letters and max_letters are nil" do
        admission_process.min_letters = nil
        admission_process.max_letters = nil
        expect(admission_process.has_letters).to eq(false)
      end
      it "should be true when min_letters is filled" do
        admission_process.min_letters = 1
        admission_process.max_letters = nil
        expect(admission_process.has_letters).to eq(true)
      end
      it "should be true when max_letters is greater than 0" do
        admission_process.min_letters = nil
        admission_process.max_letters = 2
        expect(admission_process.has_letters).to eq(true)
      end
      it "should be false when max_letters is 0" do
        admission_process.min_letters = nil
        admission_process.max_letters = 0
        expect(admission_process.has_letters).to eq(false)
      end
    end
    describe "is_open?" do
      it "should return false if today is before start date" do
        admission_process.start_date = Date.today + 1.day
        admission_process.end_date = Date.today + 1.month
        expect(admission_process.is_open?).to eq(false)
      end
      it "should return false if today is after end date" do
        admission_process.start_date = Date.today - 1.month
        admission_process.end_date = Date.today - 1.day
        expect(admission_process.is_open?).to eq(false)
      end
      it "should return true if today is between start and end date" do
        admission_process.start_date = Date.today - 1.month
        admission_process.end_date = Date.today + 1.month
        expect(admission_process.is_open?).to eq(true)
      end
    end
    describe "is_open_to_edit?" do
      it "should return false if today is before start date" do
        admission_process.start_date = Date.today + 1.day
        admission_process.edit_date = Date.today + 1.month
        admission_process.end_date = admission_process.edit_date
        expect(admission_process.is_open_to_edit?).to eq(false)
      end
      it "should return false if today is after edit date" do
        admission_process.start_date = Date.today - 1.month
        admission_process.edit_date = Date.today - 1.day
        admission_process.end_date = admission_process.edit_date
        expect(admission_process.is_open_to_edit?).to eq(false)
      end
      it "should return true if today is between start and edit date" do
        admission_process.start_date = Date.today - 1.month
        admission_process.edit_date = Date.today + 1.month
        admission_process.end_date = admission_process.edit_date
        expect(admission_process.is_open_to_edit?).to eq(true)
      end
    end
    describe "year_semester" do
      it "should return 'year.semester'" do
        admission_process.year = 2024
        admission_process.semester = 1
        expect(admission_process.year_semester).to eq("2024.1")
      end
    end
    describe "title" do
      it "should return 'name (year.semester)'" do
        admission_process.name = "Mestrado"
        admission_process.year = 2024
        admission_process.semester = 1
        expect(admission_process.title).to eq("Mestrado (2024.1)")
      end
    end
    describe "to_label" do
      it "should return 'name (year.semester)'" do
        admission_process.name = "Mestrado"
        admission_process.year = 2024
        admission_process.semester = 1
        expect(admission_process.to_label).to eq("Mestrado (2024.1)")
      end
    end
    # ToDo: admission_applications_count
    # ToDo: simple_id
    # ToDo: current_phase
    # ToDo: check_partial_consolidation_conditions
  end
end

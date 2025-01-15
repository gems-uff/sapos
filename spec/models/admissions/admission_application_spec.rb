# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionProcess, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:letter_requests).dependent(:delete_all) }
  it { should have_many(:evaluations).dependent(:destroy) }
  it { should have_many(:results).dependent(:destroy) }
  it { should have_many(:rankings).dependent(:destroy) }
  it { should have_many(:pendencies).dependent(:destroy) }

  it { should belong_to(:admission_process).required(true) }
  it { should belong_to(:filled_form).required(true) }
  it { should belong_to(:admission_phase).required(false) }
  it { should belong_to(:student).required(false) }
  it { should belong_to(:enrollment).required(false) }

  before(:all) do
    @admission_process = FactoryBot.create(:admission_process, :with_letter_template)
    @filled_form = FactoryBot.create(:filled_form)
    @destroy_later = []
  end
  after(:all) do
    @admission_process.delete
    @filled_form.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_application) do
    @filled_form.is_filled = true
    Admissions::AdmissionApplication.new(
      name: "Ana",
      email: "ana@email.com",
      admission_process: @admission_process,
      filled_form: @filled_form
    )
  end
  subject { admission_application }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    context "when allow_multiple_applications is false" do
      before { @admission_process.allow_multiple_applications = false }
      it { should validate_uniqueness_of(:email).scoped_to(:admission_process_id) }
    end
    #context "when allow_multiple_applications is false" do
   #   before { @admission_process.allow_multiple_applications = true }
   #   it { should_not validate_uniqueness_of(:email).scoped_to(:admission_process_id) }
   # end
    describe "number_of_letters_in_filled_form" do
      context "should be valid when" do
        it "filled_form is blank" do
          admission_application.filled_form = nil
          @admission_process.min_letters = 1
          expect(admission_application).not_to have_error(:min_letters).with_parameters(count: 1).on :base
          @admission_process.max_letters = 1
          admission_application.letter_requests.build
          admission_application.letter_requests.build
          expect(admission_application).not_to have_error(:max_letters).with_parameters(count: 1).on :base
        end
        it "admission_process is blank" do
          admission_application.admission_process = nil
          @admission_process.min_letters = 1
          expect(admission_application).not_to have_error(:min_letters).with_parameters(count: 1).on :base
          @admission_process.max_letters = 1
          admission_application.admission_process = @admission_process
          admission_application.letter_requests.build
          admission_application.letter_requests.build
          admission_application.admission_process = nil
          expect(admission_application).not_to have_error(:max_letters).with_parameters(count: 1).on :base
        end
        it "admission_process has no letters" do
          admission_application.admission_process = nil
          @admission_process.max_letters = 0
          expect(admission_application).not_to have_error(:min_letters).with_parameters(count: 1).on :base
          expect(admission_application).not_to have_error(:max_letters).with_parameters(count: 1).on :base
        end
        it "filled_form is not filled" do
          admission_application.filled_form.is_filled = false
          @admission_process.min_letters = 1
          expect(admission_application).not_to have_error(:min_letters).with_parameters(count: 1).on :base
          @admission_process.max_letters = 1
          admission_application.letter_requests.build
          admission_application.letter_requests.build
          expect(admission_application).not_to have_error(:max_letters).with_parameters(count: 1).on :base
        end
      end
      context "should have error min_letters when" do
        it "filled_form is filled and min_letters is greater than 0" do
          @admission_process.min_letters = 1
          @admission_process.max_letters = nil
          expect(admission_application).to have_error(:min_letters).with_parameters(count: 1).on :base
        end
      end
      context "should have error max_letters when" do
        it "filled_form is filled and max_letters is greater than 0" do
          @admission_process.max_letters = 1
          admission_application.letter_requests.build
          admission_application.letter_requests.build
          expect(admission_application).to have_error(:max_letters).with_parameters(count: 1).on :base
        end
      end
    end
  end
  # ToDo: test scopes
  # ToDo: test before_save
 

  describe "Methods" do
    # ToDo: pendency_condition
    # ToDo: phase_condition
    # ToDo: to_label
    # ToDo: requested_letters
    # ToDo: filled_letters
    # ToDo: missing_letters?
    # ToDo: prepare_missing_letters
    # ToDo: satisfies_condition
    # ToDo: attribute_as_field
    # ToDo: fields_hash
    # ToDo: consolidate_phase
    # ToDo: consolidate_phase!
    # ToDo: descriptive_status
    # ToDo: candidate_can_edit
    # ToDo: students_by_cpf
    # ToDo: students_by_email
    # ToDo: students
    # ToDo: assign_form
    # ToDo: update_student
    # ToDo: update_enrollment
    # ToDo: undo_consolidation
    # ToDo: phase_name
    # ToDo: identifier
    # ToDo: can_edit_itself
    # ToDo: ordered_rankings
  end
end

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
    # ToDo: test to_label
    # ToDo: test to_fields_hash
    # ToDo: test prepare_missing_fields
    # ToDo: test sync_fields_before
    # ToDo: test sync_fields_after
    # ToDo: test consolidate
    # ToDo: test find_cpf_field
    # ToDo: test erase_non_filled_file_fields
  end
end

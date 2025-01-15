# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionRankingResult, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:ranking_config).required(true) }
  it { should belong_to(:admission_application).required(true) }
  it { should belong_to(:filled_form).required(true) }

  before(:all) do
    @destroy_later = []
    @ranking_config = FactoryBot.create(:ranking_config)
    @admission_application = FactoryBot.create(:admission_application)
    @filled_form = FactoryBot.create(:filled_form)
  end
  after(:all) do
    @ranking_config.delete
    @admission_application.delete
    @filled_form.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_ranking_result) do
    Admissions::AdmissionRankingResult.new(
      ranking_config: @ranking_config,
      admission_application: @admission_application,
      filled_form: @filled_form
    )
  end
  subject { admission_ranking_result }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:ranking_config_id).scoped_to(:admission_application_id) }
  end
  # ToDo: after_initialize

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        @ranking_config.name = "Config"
        @admission_application.name = "Ana"
        @admission_application.token = "123"
        expect(admission_ranking_result.to_label).to eq("Config / Ana - 123")
      end
    end
    # ToDo: filled_position
    # ToDo: filled_machine
  end
end

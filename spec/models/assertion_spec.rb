# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Assertion, type: :model do
  it { should belong_to(:query).required(true) }


  let(:query) { FactoryBot.build(:query) }
  let(:assertion) do
    Assertion.new(
      name: "Test Assertion",
      assertion_template: "Template",
      query: query
    )
  end
  subject { assertion }

  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:assertion_template).on(:update) }
  end
end

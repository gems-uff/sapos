# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe AdvisementAuthorization, type: :model do
  it { should be_able_to_be_destroyed }
  let(:professor) { FactoryBot.build(:professor) }
  let(:level) { FactoryBot.build(:level) }
  let(:advisement_authorization) do
    AdvisementAuthorization.new(
      professor: professor,
      level: level
    )
  end
  subject { advisement_authorization }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:professor).required(true) }
    it { should belong_to(:level).required(true) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        level_name = "AuthorizedLevel"
        advisement_authorization.level = Level.new(:name => level_name)
        expect(advisement_authorization.to_label).to eql(level_name)
      end
    end
  end
end

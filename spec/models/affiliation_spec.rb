# frozen_string_literal: true

require "spec_helper"

RSpec.describe Affiliation, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:institution) }
  it { should belong_to(:professor) }
  let(:affiliation) { FactoryBot.create :affiliation }

  subject { affiliation }
  context "Validation" do
    it { should be_valid }
    it { should validate_presence_of(:active) }
    it { should validate_presence_of(:start_date) }
  end
end

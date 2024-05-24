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
    it { should validate_presence_of(:start_date) }
    context "Active" do
      let(:professor) { FactoryBot.create :professor}
      let(:affiliation_active) { FactoryBot.create :affiliation, professor: professor, active: true}
      let(:affiliation_inactive) { FactoryBot.create :affiliation, professor: professor, active: false}
      let(:affiliation_teste_active) { FactoryBot.build :affiliation, professor: professor, active: true}
      let(:affiliation_teste_inactive) { FactoryBot.build :affiliation, professor: professor, active: false}

      it "When active, do not add new affiliation active" do
        affiliation_active
        aff = FactoryBot.build(:affiliation, professor: professor, active: true)
        expect(aff).to be_invalid
      end
      context "When inactive, you can add new affiliation active/inactive" do
        before do
          affiliation_inactive
        end
        it { expect(affiliation_teste_active).to be_valid }
        it { expect(affiliation_teste_inactive).to be_valid }
      end
      it "when inactive, you can add multiple affiliation" do
        affiliation_inactive
        expect(affiliation_inactive).to be_valid
        affiliation_teste_inactive.save!
        expect(Affiliation.all.count).to be_eql(2)
      end
    end
    context "Active e End Date" do
      let(:affiliation_active) { FactoryBot.create :affiliation, end_date: nil, active: true }
      let(:affiliation_inactive_valid) { FactoryBot.create :affiliation, end_date: Time.now, active: false }
      let(:affiliation_inactive_invalid) { FactoryBot.build :affiliation, end_date: nil, active: false }
      context "When active, don't need end date" do
        it { expect(affiliation_active).to be_valid }
      end
      context "When inactive, need an end date" do
        it { expect(affiliation_inactive_valid).to be_valid }
        it { expect(affiliation_inactive_invalid).to be_invalid }
      end
    end
  end
end

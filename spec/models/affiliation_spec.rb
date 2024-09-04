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
      let(:professor) { FactoryBot.create :professor }
      let(:affiliation_active) { FactoryBot.create :affiliation, professor: professor, start_date: Time.now, end_date: nil }
      let(:affiliation_inactive) { FactoryBot.create :affiliation,
                                                     professor: professor,
                                                     start_date: Time.now + 1.day,
                                                     end_date: Time.now + 2.day}
      let(:affiliation_teste_active) { FactoryBot.build :affiliation, professor: professor, start_date: Time.now + 2.day }
      let(:affiliation_teste_inactive) { FactoryBot.build :affiliation,
                                                          professor: professor,
                                                          start_date: Time.now + 3.day,
                                                          end_date: Time.now + 4.day }

      it "When active, do not add new affiliation active" do
        affiliation_active
        aff = FactoryBot.build(:affiliation, professor: professor, end_date: nil)
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
      let(:affiliation_active) { FactoryBot.create :affiliation, end_date: nil }
      let(:affiliation_inactive_valid) { FactoryBot.create :affiliation, end_date: Time.now }
      let(:affiliation_inactive_invalid) { FactoryBot.build :affiliation, professor: affiliation_active.professor, end_date: nil }
      context "When active, don't need end date" do
        it { expect(affiliation_active).to be_valid }
      end
      context "When inactive, need an end date" do
        before(:each) do
          affiliation_active
        end
        it { expect(affiliation_inactive_valid).to be_valid }
        it { expect(affiliation_inactive_invalid).to be_invalid }
      end
    end
  end
  
  context "Scope" do
    context "date_professor" do
      let!(:professor) { FactoryBot.create :professor }
      let!(:affiliation_active) { FactoryBot.create :affiliation, professor: professor, start_date: Time.now, end_date: nil }
      let!(:affiliation_inactive) do
        FactoryBot.create :affiliation, professor: professor, start_date: Time.now - 1.day, end_date: Time.now
      end


      it { expect(Affiliation.professor_date(professor, Time.now).last).to eq(affiliation_active) }
      it { expect(Affiliation.professor_date(professor, Time.now - 1.days).last).to eq(affiliation_inactive) }
    end
  end
end

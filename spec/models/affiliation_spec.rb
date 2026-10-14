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

    # Um professor tem uma filiação por vez: duas que se cruzam fariam o
    # on_date casar duas instituições para a mesma data. O término é
    # exclusivo, como no on_date.
    context "Periods that overlap" do
      let(:professor) { FactoryBot.create :professor }
      before(:each) do
        FactoryBot.create :affiliation, professor: professor,
                          start_date: Time.zone.local(2015, 1, 1), end_date: Time.zone.local(2020, 1, 1)
      end

      it "rejects a closed period that crosses an existing closed one" do
        other = FactoryBot.build :affiliation, professor: professor,
                                 start_date: Time.zone.local(2018, 1, 1), end_date: Time.zone.local(2019, 1, 1)
        expect(other).to have_error(:overlapping_period).on(:base)
      end

      # Controle do exemplo acima: com término exclusivo, começar no dia em que
      # a anterior termina não cruza.
      it "accepts a period that starts on the day the previous one ends" do
        other = FactoryBot.build :affiliation, professor: professor,
                                 start_date: Time.zone.local(2020, 1, 1), end_date: nil
        expect(other).to be_valid
      end

      it "accepts a crossing period of another professor" do
        other = FactoryBot.build :affiliation, start_date: Time.zone.local(2018, 1, 1), end_date: nil
        expect(other).to be_valid
      end

      # Só o período alterado é julgado: uma filiação que já se cruzava e que
      # ninguém tocou nas datas continua editável.
      it "still saves an untouched overlapping record when only the institution changes" do
        legado = FactoryBot.build :affiliation, professor: professor,
                                  start_date: Time.zone.local(2018, 1, 1), end_date: nil
        legado.save!(validate: false)
        legado.institution = FactoryBot.create :institution
        expect(legado).to be_valid
      end
    end

    # As colunas de filiação são datetime, cujo cast passa por Time.zone.parse
    # e aceita mais que o date_picker -- "31/02/2026" vira 03/03/2026. Por isso
    # só a entrada que nenhum parser entende serve aqui.
    context "An unparseable end date" do
      it "is rejected instead of saved as an open period" do
        aff = FactoryBot.build :affiliation, end_date: nil
        aff.end_date = "banana"
        expect(aff.end_date).to be_nil, "o cast já descartou a entrada"
        expect(aff).to have_error(:invalid_date).on(:end_date)
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

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report, type: :model do
  let(:carrierwave_file) { CarrierWave::Storage::ActiveRecord::ActiveRecordFile.new }
  let(:report) { FactoryBot.create(:report, carrierwave_file: carrierwave_file) }

  describe "#to_label" do
    it "returns the correct label format" do
      expect(report.to_label).to eq("#{report.user.name} - #{I18n.l(report.created_at, format: '%d/%m/%Y %H:%M')}")
    end
  end

  describe "associations" do
    it { should belong_to(:user).with_foreign_key("generated_by_id") }
    it { should belong_to(:carrierwave_file).with_foreign_key("carrierwave_file_id").class_name("CarrierWave::Storage::ActiveRecord::ActiveRecordFile").optional }
    it { should belong_to(:invalidated_by).with_foreign_key("invalidated_by_id").class_name("User").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:file_name) }
  end

  describe "#expired?" do
    it "is true when expires_at is in the past" do
      report.expires_at = Date.yesterday
      expect(report.expired?).to be true
    end

    it "is false on the expiration date itself (valid until that day)" do
      report.expires_at = Date.today
      expect(report.expired?).to be false
    end

    it "is false when expires_at is in the future" do
      report.expires_at = Date.tomorrow
      expect(report.expired?).to be false
    end

    it "is false when expires_at is nil" do
      report.expires_at = nil
      expect(report.expired?).to be false
    end
  end

  # O escopo decide o que a rotina de limpeza apaga; o predicado decide o que o
  # download recusa. Concordam hoje porque saem do mesmo expiry_cutoff, e este
  # grupo e o que impede que voltem a divergir: cobre o limite pelos dois lados
  # de uma vez, inclusive o proprio dia do vencimento, que e a unica data em que
  # um erro de `<` para `<=` apareceria.
  describe ".expired" do
    let(:datas) { { Date.yesterday => true, Date.today => false, Date.tomorrow => false, nil => false } }

    it "seleciona exatamente os registros que #expired? aprova" do
      criados = datas.keys.index_with do |data|
        FactoryBot.create(:report, expires_at: data)
      end

      vencidos = Report.expired.pluck(:id)

      datas.each do |data, esperado|
        registro = criados[data]
        expect(vencidos.include?(registro.id)).to eq(esperado),
          "escopo divergiu em expires_at=#{data.inspect}"
        expect(registro.expired?).to eq(esperado),
          "predicado divergiu em expires_at=#{data.inspect}"
      end
    end
  end
end

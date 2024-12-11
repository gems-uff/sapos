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
  end
end

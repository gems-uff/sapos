# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScholarshipsController, type: :controller do
  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  describe "Search" do
    describe "condition_for_available_column" do
      it "should include the scholarship if there is no allocation, end_date is nil and search date is after start_date" do
        @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: Date.parse("2012/01/01"), end_date: nil)
        condition = ScholarshipsController.condition_for_available_column(:available, { use: "yes", month: "2", year: "2013" }, "")
        expect(Scholarship.where(condition.map(&:to_sql).join(" OR "))).to include(scholarship)
      end

      it "should not include the scholarship if there is no allocation, end_date is nil and search date is before start_date" do
        @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: Date.parse("2012/01/01"), end_date: nil)
        condition = ScholarshipsController.condition_for_available_column(:available, { use: "yes", month: "2", year: "2011" }, "")
        expect(Scholarship.where(condition.map(&:to_sql).join(" OR "))).not_to include(scholarship)
      end

      it "should not include the scholarship if there is no allocation, search date is after end_date" do
        @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2015/01/31"))
        condition = ScholarshipsController.condition_for_available_column(:available, { use: "yes", month: "2", year: "2016" }, "")
        expect(Scholarship.where(condition.map(&:to_sql).join(" OR "))).not_to include(scholarship)
      end

      it "should include the scholarship if there is allocation, but it ends before the search date" do
        @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2015/01/31"))
        FactoryBot.create(:scholarship_duration, scholarship_id: scholarship.id, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2013/01/31"), cancel_date: nil)
        condition = ScholarshipsController.condition_for_available_column(:available, { use: "yes", month: "2", year: "2013" }, "")
        expect(Scholarship.where(condition.map(&:to_sql).join(" OR "))).to include(scholarship)
      end

      it "should not include the scholarship if there is allocation, and it ends after the search date" do
        @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2015/01/31"))
        FactoryBot.create(:scholarship_duration, scholarship_id: scholarship.id, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2013/03/31"), cancel_date: nil)
        condition = ScholarshipsController.condition_for_available_column(:available, { use: "yes", month: "2", year: "2013" }, "")
        expect(Scholarship.where(condition.map(&:to_sql).join(" OR "))).not_to include(scholarship)
      end

      it "should include the scholarship if there is allocation, and it ends after the search date, but was cancelled before" do
        @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2015/01/31"))
        FactoryBot.create(:scholarship_duration, scholarship_id: scholarship.id, start_date: Date.parse("2012/01/01"), end_date: Date.parse("2013/03/31"), cancel_date: Date.parse("2013/01/31"))
        condition = ScholarshipsController.condition_for_available_column(:available, { use: "yes", month: "2", year: "2013" }, "")
        expect(Scholarship.where(condition.map(&:to_sql).join(" OR "))).to include(scholarship)
      end
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe DateUtils do
  describe "Add to date" do
    context "with no semesters, months, or days" do
      it "returns the end of the current month" do
        date = Date.new(2024, 1, 15)
        expect(DateUtils.add_to_date(date, 0, 0, 0)).to eq(Date.new(2024, 1, 31))
      end
    end

    context "in March" do
      it "advances 1 semester, 1 month and 5 days to September 5" do
        date = Date.new(2024, 3, 1)
        expect(DateUtils.add_to_date(date, 1, 1, 5)).to eq(Date.new(2024, 9, 5))
      end
    end

    context "not in March" do
      it "advances 1 semester, 1 month and 5 days from August to April 5" do
        date = Date.new(2024, 8, 1)
        expect(DateUtils.add_to_date(date, 1, 1, 5)).to eq(Date.new(2025, 4, 5))
      end
    end

    context "with 2 semesters" do
      it "advances 11 months" do
        date = Date.new(2024, 1, 15)
        expect(DateUtils.add_to_date(date, 2, 0, 0)).to eq(Date.new(2024, 12, 31))
      end
    end
  end

  describe "Add hash to date" do
    it "delegates to add_to_date using the hash keys" do
      date = Date.new(2024, 1, 15)
      hash = { semesters: 1, months: 0, days: 0 }
      expect(DateUtils.add_hash_to_date(date, hash)).to eq(
        DateUtils.add_to_date(date, 1, 0, 0)
      )
    end
  end
end

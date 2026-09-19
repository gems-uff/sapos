# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ClassSchedulesHelper, type: :helper do
  describe "class_schedule_day_groups" do
    it "groups days that share the same time slot and room" do
      allocations = [
        { day: "Segunda", start_time: 18, end_time: 20, room: "304" },
        { day: "Quarta", start_time: 18, end_time: 20, room: "304" }
      ]

      groups = helper.class_schedule_day_groups(allocations)

      expect(groups).to eq(
        [{ days: ["Segunda", "Quarta"], start_time: 18, end_time: 20, room: "304" }]
      )
    end

    it "keeps different time slots as separate groups, in day order" do
      allocations = [
        { day: "Quinta", start_time: 18, end_time: 20, room: "202" },
        { day: "Terça", start_time: 18, end_time: 20, room: "202" },
        { day: "Segunda", start_time: 10, end_time: 12, room: "101" }
      ]

      groups = helper.class_schedule_day_groups(allocations)

      expect(groups).to eq(
        [
          { days: ["Segunda"], start_time: 10, end_time: 12, room: "101" },
          { days: ["Terça", "Quinta"], start_time: 18, end_time: 20, room: "202" }
        ]
      )
    end
  end

  describe "class_schedule_days_label" do
    it "returns a single day unchanged, pluralized" do
      expect(helper.class_schedule_days_label(["Terça"])).to eq("Terças")
    end

    it "joins two days with e" do
      expect(helper.class_schedule_days_label(["Segunda", "Quarta"])).to eq(
        "Segundas e Quartas"
      )
    end

    it "joins three or more days with commas and a final e" do
      expect(
        helper.class_schedule_days_label(["Segunda", "Quarta", "Sexta"])
      ).to eq("Segundas, Quartas e Sextas")
    end
  end

  describe "class_schedule_allocation_label" do
    it "includes the room when present" do
      group = { days: ["Terça"], start_time: 10, end_time: 12, room: "208" }

      expect(helper.class_schedule_allocation_label(group)).to eq(
        "Terças, 10h às 12h, Sala: 208"
      )
    end

    it "omits the room when absent" do
      group = { days: ["Terça"], start_time: 10, end_time: 12, room: nil }

      expect(helper.class_schedule_allocation_label(group)).to eq(
        "Terças, 10h às 12h"
      )
    end
  end
end

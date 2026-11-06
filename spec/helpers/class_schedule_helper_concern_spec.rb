# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ClassScheduleHelperConcern, type: :helper do
  # A coluna vem do cabeçalho devolvido, e não da fórmula do próprio concern:
  # assim o spec acusa frase falada que não bate com o dia que o vidente lê.
  def day_column(table, day)
    table[:header][0].index(day)
  end

  def day_columns(table)
    (table[:first]..table[:last]).map do |index|
      day_column(table, I18n.translate("date.day_names")[index])
    end
  end

  describe "class_schedule_spoken_allocation" do
    it "includes the room when present" do
      allocation = FactoryBot.create(
        :allocation, day: "Quinta", start_time: 14, end_time: 16, room: "310"
      )

      expect(helper.class_schedule_spoken_allocation(allocation)).to eq(
        "Quinta, 14h às 16h, Sala: 310"
      )
    end

    it "omits the room when absent" do
      allocation = FactoryBot.create(
        :allocation, day: "Quinta", start_time: 14, end_time: 16, room: nil
      )

      expect(helper.class_schedule_spoken_allocation(allocation)).to eq(
        "Quinta, 14h às 16h"
      )
    end
  end

  describe "prepare_class_schedule_table" do
    it "aligns the spoken phrase with the visible time/room cell" do
      course_class = FactoryBot.create(:course_class)
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Terça",
        start_time: 10, end_time: 12, room: "208"
      )

      table = helper.prepare_class_schedule_table([course_class], [])
      col = day_column(table, "Terça")

      expect(table[:data].first[col]).to eq("10-12\n208")
      expect(table[:actual].first[col]).to eq("Terça, 10h às 12h, Sala: 208")
    end

    it "joins more than one allocation on the same day into a single phrase" do
      course_class = FactoryBot.create(:course_class)
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Segunda",
        start_time: 8, end_time: 10, room: "101"
      )
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Segunda",
        start_time: 14, end_time: 16, room: "102"
      )

      table = helper.prepare_class_schedule_table([course_class], [])
      col = day_column(table, "Segunda")

      expect(table[:actual].first[col]).to eq(
        "Segunda, 8h às 10h, Sala: 101. Segunda, 14h às 16h, Sala: 102"
      )
    end

    it "draws an asterisk on every star cell but speaks on the name cell only" do
      course_class = FactoryBot.create(:course_class)

      table = helper.prepare_class_schedule_table([course_class], [])
      noschedule = I18n.t("activerecord.attributes.class_schedule.table.noschedule")
      name = table[:data].first[1]

      # Todo dia continua com asterisco visível e sem frase própria; a frase
      # vai uma vez só, na célula do nome.
      expect(table[:actual].first[1]).to eq("#{name}. #{noschedule}")
      day_columns(table).each do |col|
        expect(table[:data].first[col]).to eq("*\n ")
        expect(table[:actual].first[col]).to be_nil
      end
    end

    it "leaves a day cell without any allocation silent (nil)" do
      course_class = FactoryBot.create(:course_class)
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Segunda",
        start_time: 8, end_time: 10
      )
      other_day = (
        I18n.translate("date.day_names") - ["Segunda"]
      ).find { |d| I18n.translate("date.day_names").index(d).between?(1, 5) }

      table = helper.prepare_class_schedule_table([course_class], [])
      col = day_column(table, other_day)

      expect(table[:data].first[col]).to eq("")
      expect(table[:actual].first[col]).to be_nil
    end

    it "speaks the course name plus the no-schedule text for an on-demand course" do
      course_type = FactoryBot.create(:course_type, on_demand: true)
      course = FactoryBot.create(
        :course, name: "Tópicos Avançados", course_type: course_type
      )

      table = helper.prepare_class_schedule_table([], [course])
      noschedule = I18n.t("activerecord.attributes.class_schedule.table.noschedule")

      expect(table[:actual].first[1]).to eq("Tópicos Avançados. #{noschedule}")
      day_columns(table).each do |col|
        expect(table[:actual].first[col]).to be_nil
      end
    end

    it "keeps the spoken grid aligned with the visible grid after sorting by name" do
      course_z = FactoryBot.create(:course, name: "Zoologia")
      course_a = FactoryBot.create(:course, name: "Álgebra")
      course_class_z = FactoryBot.create(:course_class, course: course_z)
      course_class_a = FactoryBot.create(:course_class, course: course_a)
      FactoryBot.create(
        :allocation, course_class: course_class_a, day: "Segunda",
        start_time: 8, end_time: 10
      )

      table = helper.prepare_class_schedule_table(
        [course_class_z, course_class_a], []
      )
      col = day_column(table, "Segunda")
      noschedule = I18n.t("activerecord.attributes.class_schedule.table.noschedule")

      expect(table[:data].map { |row| row[1] }).to eq(["Álgebra", "Zoologia"])
      expect(table[:actual][0][col]).to eq("Segunda, 8h às 10h")
      expect(table[:actual][1][1]).to eq("Zoologia. #{noschedule}")
    end
  end
end

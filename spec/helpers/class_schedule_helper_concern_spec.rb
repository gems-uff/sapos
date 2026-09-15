# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ClassScheduleHelperConcern, type: :helper do
  # prepare_class_schedule_list chama rescue_blank_text, definido em
  # ApplicationHelper -- garantir a mixagem em vez de depender da inclusao
  # automatica de helpers do rspec-rails.
  before { helper.extend(ApplicationHelper) }

  describe "prepare_class_schedule_list" do
    it "lists a course_class with all of its allocations" do
      course_class = FactoryBot.create(:course_class)
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Segunda",
        start_time: 10, end_time: 12, room: "101"
      )
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Quarta",
        start_time: 10, end_time: 12, room: "101"
      )

      list = helper.prepare_class_schedule_list([course_class], [])

      expect(list.size).to eq(1)
      expect(list.first[:no_schedule]).to eq(false)
      expect(list.first[:allocations]).to contain_exactly(
        { day: "Segunda", start_time: 10, end_time: 12, room: "101" },
        { day: "Quarta", start_time: 10, end_time: 12, room: "101" }
      )
    end

    it "includes the professor name" do
      professor = FactoryBot.create(:professor, name: "Ana Paula")
      course_class = FactoryBot.create(:course_class, professor: professor)

      list = helper.prepare_class_schedule_list([course_class], [])

      expect(list.first[:professor]).to eq("Ana Paula")
    end

    it "marks a course_class without allocations as no_schedule" do
      course_class = FactoryBot.create(:course_class)

      list = helper.prepare_class_schedule_list([course_class], [])

      expect(list.first[:no_schedule]).to eq(true)
      expect(list.first[:allocations]).to eq([])
    end

    it "excludes a course_class marked as not_schedulable" do
      course_class = FactoryBot.create(:course_class, not_schedulable: true)

      list = helper.prepare_class_schedule_list([course_class], [])

      expect(list).to be_empty
    end

    it "excludes a course_class whose course_type is not schedulable" do
      course_type = FactoryBot.create(:course_type, schedulable: false)
      course = FactoryBot.create(:course, course_type: course_type)
      course_class = FactoryBot.create(:course_class, course: course)

      list = helper.prepare_class_schedule_list([course_class], [])

      expect(list).to be_empty
    end

    it "lists an on-demand course without a real schedule and a blank professor" do
      course_type = FactoryBot.create(:course_type, on_demand: true)
      course = FactoryBot.create(
        :course, name: "Tópicos Avançados", course_type: course_type
      )
      course_class = FactoryBot.create(:course_class, course: course)

      list = helper.prepare_class_schedule_list([course_class], [course])

      expect(list.size).to eq(1)
      expect(list.first[:name]).to eq("Tópicos Avançados")
      expect(list.first[:no_schedule]).to eq(true)
      expect(list.first[:professor]).to eq("")
    end

    it "omits an on-demand course with no professor when it is not available" do
      course_type = FactoryBot.create(:course_type, on_demand: true)
      course = FactoryBot.create(
        :course, course_type: course_type, available: false
      )

      list = helper.prepare_class_schedule_list([], [course])

      expect(list).to be_empty
    end

    it "sorts entries by transliterated name" do
      course_z = FactoryBot.create(:course, name: "Zoologia")
      course_a = FactoryBot.create(:course, name: "Álgebra")
      course_class_z = FactoryBot.create(:course_class, course: course_z)
      course_class_a = FactoryBot.create(:course_class, course: course_a)

      list = helper.prepare_class_schedule_list(
        [course_class_z, course_class_a], []
      )

      expect(list.map { |item| item[:name] }).to eq(["Álgebra", "Zoologia"])
    end
  end
end

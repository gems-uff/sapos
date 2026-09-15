# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ClassSchedulesPdfHelper, type: :helper do
  # class_schedule_list_pdf roda dentro da view, onde os rótulos de dia/horário
  # (ClassSchedulesHelper) e o rescue_blank_text (ApplicationHelper) estão à
  # mão. Fora de uma requisição eles não entram sozinhos.
  before do
    helper.extend(ClassSchedulesHelper)
    helper.extend(ApplicationHelper)
  end

  describe "class_schedule_list_pdf" do
    let(:pdf) { Prawn::Document.new }

    # Lê de volta o texto impresso; os espaços caem porque o prawn pode partir
    # uma palavra em mais de um run e a asserção não deve depender disso.
    def printed(document)
      PDF::Reader.new(StringIO.new(document.render)).pages.first.text.delete(" ")
    end

    it "prints the allocation label of a scheduled class" do
      professor = FactoryBot.create(:professor, name: "Ana Paula")
      course = FactoryBot.create(:course, name: "Estruturas de Dados")
      course_class = FactoryBot.create(
        :course_class, course: course, professor: professor
      )
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Terça",
        start_time: 10, end_time: 12, room: "208"
      )

      helper.class_schedule_list_pdf(
        pdf, course_classes: [course_class], on_demand: []
      )

      expect(printed(pdf)).to include("Sala:208")
    end

    it "prints the class schedule custom variable when present" do
      allow(CustomVariable).to receive(:class_schedule_text)
        .and_return("Matriculas abertas")

      helper.class_schedule_list_pdf(pdf, course_classes: [], on_demand: [])

      expect(printed(pdf)).to include("Matriculasabertas")
    end

    it "keeps a markup character in the name as a literal character" do
      # Sem o escape, o prawn leria "<X>" como uma tag e o texto sumiria (ou
      # levantaria); com o escape ele reaparece impresso.
      course = FactoryBot.create(:course, name: "Topicos <X>")
      course_class = FactoryBot.create(:course_class, course: course)

      helper.class_schedule_list_pdf(
        pdf, course_classes: [course_class], on_demand: []
      )

      expect(printed(pdf)).to include("<X>")
    end
  end
end

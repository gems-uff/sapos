# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ClassSchedulesPdfHelper, type: :helper do
  before { helper.extend(PdfHelper) }

  # Mesmo documento que app/views/class_schedules/class_schedule_pdf.pdf.prawn
  # monta: A4 paisagem, com as fontes de produção.
  def render_schedule(course_classes, on_demand: [])
    helper.new_document(
      "class_schedule.pdf", "QUADRO DE HORÁRIOS",
      page_layout: :landscape, pdf_type: :schedule
    ) do |pdf|
      helper.class_schedule_table(
        pdf, course_classes: course_classes, on_demand: on_demand
      )
    end
  end

  # O que o leitor de tela ouve, lido dos operadores e não do page.text (ver
  # spec/support/pdf_actual_text.rb).
  def spoken(document)
    PdfActualText.actual_texts(document).first
  end

  def drawn(document)
    PDF::Reader.new(StringIO.new(PdfActualText.without_actual_text(document)))
      .pages.first.text
  end

  def scheduled_class(day, room: "208")
    course_class = FactoryBot.create(:course_class)
    FactoryBot.create(
      :allocation, course_class: course_class, day: day,
      start_time: 10, end_time: 12, room: room
    )
    course_class
  end

  let(:noschedule) do
    I18n.t("activerecord.attributes.class_schedule.table.noschedule")
  end

  describe "class_schedule_table" do
    # Todos os dias, e não só um: a posição da coluna era o que o page.text
    # embaralhava.
    %w[Segunda Terça Quarta Quinta Sexta].each do |day|
      it "makes a scheduled cell on #{day} speak the day, time and room" do
        document = render_schedule([scheduled_class(day)])

        expect(spoken(document)).to eq(["#{day}, 10h às 12h, Sala: 208"])
        expect(drawn(document)).to include("10-12")
      end
    end

    # Com alias_method, a segunda carga encadeava o método nele mesmo e todo
    # PDF com tabela, de qualquer relatório, estourava a pilha.
    it "survives a second load of the ActualText patch" do
      load Rails.root.join("config/initializers/prawn_actual_text.rb")

      document = render_schedule([scheduled_class("Terça")])

      expect(spoken(document)).to eq(["Terça, 10h às 12h, Sala: 208"])
    end

    it "declares the PDF version that ActualText needs" do
      document = render_schedule([scheduled_class("Terça")])

      expect(document).to start_with("%PDF-1.5")
    end

    it "speaks the name plus the no-schedule text once, leaving the asterisks drawn" do
      course = FactoryBot.create(:course, name: "Tópicos em IA")
      course_class = FactoryBot.create(:course_class, course: course)

      document = render_schedule([course_class])

      expect(spoken(document)).to eq(["Tópicos em IA. #{noschedule}"])
      expect(drawn(document)).to match(/Tópicos em IA(\s+\*){5}/)
    end

    # A célula visível escapa "<" para o inline_format; a frase falada não
    # passa por ele e tem de levar o nome como o usuário o digitou.
    it "speaks a name with '<' as typed, not escaped" do
      course = FactoryBot.create(:course, name: "Tópicos <IA>")
      course_class = FactoryBot.create(:course_class, course: course)

      document = render_schedule([course_class])

      expect(spoken(document)).to eq(["Tópicos <IA>. #{noschedule}"])
      expect(drawn(document)).to include("Tópicos <IA>")
    end

    it "speaks an on-demand course name plus the no-schedule text" do
      course_type = FactoryBot.create(:course_type, on_demand: true)
      course = FactoryBot.create(
        :course, name: "Tópicos Avançados", course_type: course_type
      )

      document = render_schedule([], on_demand: [course])

      expect(spoken(document)).to eq(["Tópicos Avançados. #{noschedule}"])
    end

    # O escape da #265 só alcançava o nome de turma: no curso sob demanda, o
    # inline_format lia "<a definir>" como tag e o nome saía cortado.
    it "draws an on-demand course name with '<' whole" do
      course_type = FactoryBot.create(:course_type, on_demand: true)
      course = FactoryBot.create(
        :course, name: "Seminário <a definir>", course_type: course_type
      )

      document = render_schedule([], on_demand: [course])

      expect(drawn(document)).to include("Seminário <a definir>")
      expect(spoken(document)).to eq(["Seminário <a definir>. #{noschedule}"])
    end

    it "gives no ActualText to the days without allocation of a scheduled class" do
      document = render_schedule([scheduled_class("Segunda")])

      expect(spoken(document)).to eq(["Segunda, 10h às 12h, Sala: 208"])
      expect(drawn(document)).not_to include(noschedule)
    end
  end
end

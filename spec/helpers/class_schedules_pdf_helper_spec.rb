# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ClassSchedulesPdfHelper, type: :helper do
  # class_schedule_table chama simple_pdf_table (PdfHelper) e
  # rescue_blank_text (ApplicationHelper, incluido por PdfHelper). Fora de uma
  # requisição eles não entram sozinhos.
  before { helper.extend(PdfHelper) }

  # O golden-master (spec/support/golden_master.rb) usa o mesmo pdf-reader
  # para extrair o page.text; a Issue #224 confirmou por spike que ele
  # substitui o texto visível pelo ActualText, então esta leitura é o que o
  # leitor de tela ouviria.
  def spoken_text(pdf)
    PDF::Reader.new(StringIO.new(pdf.render)).pages.first.text
  end

  # simple_pdf_table pede a fonte "FreeSans" explicitamente no cell_style; em
  # produção quem registra a família é new_document (app/helpers/pdf_helper.rb),
  # que não é chamado aqui. Sem isto o Prawn recusa a fonte desconhecida.
  def pdf_with_fonts
    pdf = Prawn::Document.new(page_layout: :landscape)
    freefont_directory = "#{Rails.root}/vendor/assets/fonts/gnu-freefont/"
    pdf.font_families.update("FreeSans" => {
      normal: freefont_directory + "FreeSans.ttf",
      bold: freefont_directory + "FreeSansBold.ttf",
      italic: freefont_directory + "FreeSansOblique.ttf",
      bold_italic: freefont_directory + "FreeSansBoldOblique.ttf"
    })
    pdf
  end

  describe "class_schedule_table" do
    it "makes a scheduled cell speak the day, time and room via ActualText" do
      professor = FactoryBot.create(:professor, name: "Ana Paula")
      course = FactoryBot.create(:course, name: "Estruturas de Dados")
      course_class = FactoryBot.create(
        :course_class, course: course, professor: professor
      )
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Terça",
        start_time: 10, end_time: 12, room: "208"
      )

      pdf = pdf_with_fonts
      helper.class_schedule_table(
        pdf, course_classes: [course_class], on_demand: []
      )

      expect(spoken_text(pdf)).to include("Terça, 10h às 12h, Sala: 208")
    end

    it "speaks the course name plus the no-schedule text, without corrupting neighbors" do
      course = FactoryBot.create(:course, name: "Tópicos em IA")
      course_class = FactoryBot.create(:course_class, course: course)

      pdf = pdf_with_fonts
      helper.class_schedule_table(
        pdf, course_classes: [course_class], on_demand: []
      )

      noschedule = I18n.t("activerecord.attributes.class_schedule.table.noschedule")
      # Asserção pela frase INTEIRA e intacta, não só pela presença do texto de
      # "a combinar": a fala não pode entrar em nenhuma célula de dia -- são 5
      # colunas estreitas lado a lado com glifo real (o "*"), e ali a extração
      # de texto por posição de glifo intercala os vizinhos no meio da frase.
      expect(spoken_text(pdf)).to include("Tópicos em IA. #{noschedule}")
    end

    it "leaves a day without allocation silent, without marking it as no-schedule" do
      course_class = FactoryBot.create(:course_class)
      FactoryBot.create(
        :allocation, course_class: course_class, day: "Segunda",
        start_time: 8, end_time: 10
      )

      pdf = pdf_with_fonts
      helper.class_schedule_table(
        pdf, course_classes: [course_class], on_demand: []
      )

      # Só a turma inteiramente sem alocação vira asterisco; um dia vazio ao
      # lado de um dia agendado é célula muda, não célula de "a combinar".
      expect(spoken_text(pdf)).not_to include(
        I18n.t("activerecord.attributes.class_schedule.table.noschedule")
      )
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ClassScheduleHelperConcern
  def prepare_class_schedule_table(
    course_classes, on_demand, advisement_authorizations = nil,
    keep_on_demand = false, used_to_render_a_pdf_report: false
  )
    advisement_authorizations ||= []
    star = false
    first = 1
    last = 5
    course_classes.each do |course_class|
      course_class.allocations.each do |allocation|
        index = I18n.translate("date.day_names").index(allocation.day)
        unless index.nil?
          first = index if index < first
          last = index if index > last
        end
      end
    end
    header = [[
      "meta",
      "#{I18n.t("activerecord.attributes.class_schedule.table.course_name")}"
    ]]
    (first..last).each do |index|
      header[0] << "#{I18n.translate("date.day_names")[index]}"
    end
    header[0] << "#{I18n.t(
      "activerecord.attributes.class_schedule.table.professor"
    )}"

    noschedule = I18n.t(
      "activerecord.attributes.class_schedule.table.noschedule"
    )

    # Cada linha é o par [visível, falado]: o visível é o que o vidente lê na
    # célula; o falado é a frase que o leitor de tela deve anunciar via
    # ActualText (nil em célula que se descreve sozinha ou muda). Os dois viajam
    # juntos pela ordenação no fim, para não desalinharem.
    rows = []
    on_demand_professors = {}

    course_classes.each do |course_class|
      next if course_class.not_schedulable

      course_type = course_class.course.course_type
      next unless course_type.schedulable

      course = header[0].map { |x| [] }
      spoken = header[0].map { |x| [] }

      course[0] = {
        id: course_class.id, course_id: course_class.course_id,
        on_demand: course_type.on_demand
      }
      course[1] = used_to_render_a_pdf_report ?
        course_class.name_with_class_formated_to_reports :
        course_class.name_with_class

      course_class.allocations.each do |allocation|
        index = I18n.translate("date.day_names").index(allocation.day)
        course[index + 2 - first] << allocation.to_shortlabel
        spoken[index + 2 - first] << class_schedule_spoken_allocation(allocation)
      end

      course = course.map { |x| x.kind_of?(Array) ? x.join("\n") : x }
      spoken = spoken.map do |x|
        x.kind_of?(Array) ? (x.empty? ? nil : x.join(". ")) : nil
      end

      if course_class.allocations.empty?
        (first..last).each do |index|
          course[index + 2 - first] = "*\n "
        end
        # A frase não vai em nenhuma célula de dia: são 5 células estreitas
        # lado a lado, cada uma com um glifo real (o próprio "*") -- e
        # extração de texto por posição de glifo (pdf-reader, e por extensão
        # qualquer leitor que dependa disso) intercala os glifos reais das
        # vizinhas no meio da frase longa. Uma célula sem conteúdo próximo
        # concorrendo não sofre isso: por isso a frase entra na célula do
        # nome, larga e sem vizinho disputando a mesma linha dentro dela.
        #
        # Nome CRU (name_with_class), não course[1]: este último pode vir de
        # name_with_class_formated_to_reports, que escapa "<" para "&lt;" por
        # causa do inline_format da célula visível. O ActualText é string
        # Unicode pura, sem inline_format, então o "&lt;" seria falado literal.
        spoken[1] = "#{course_class.name_with_class}. #{noschedule}"
        star = true
      end

      course[-1] = rescue_blank_text(course_class.professor, method_call: :name)
      if ! course_type.on_demand || keep_on_demand
        rows << [course, spoken]
      else
        (
          on_demand_professors[course_class.course_id] ||= []
        ) << course_class.professor
      end
    end

    demand_rows = []

    on_demand.each do |course|
      professors = advisement_authorizations
      found_professors = on_demand_professors[course.id]
      if found_professors.present?
        different_professors = found_professors.filter do |prof|
          ! advisement_authorizations.include? prof
        end
        professors = different_professors + advisement_authorizations
      end
      next unless found_professors.present? || course.available

      course_data = header[0].map { |x| "" }
      spoken_data = header[0].map { |x| nil }
      course_data[0] = {
        id: nil, course_id: course.id,
        on_demand: true, professors: professors
      }
      course_data[1] = course.name
      (first..last).each do |index|
        course_data[index + 2 - first] = "*\n "
      end
      spoken_data[1] = "#{course_data[1]}. #{noschedule}"
      course_data[-1] = ""
      star = true
      demand_rows << [course_data, spoken_data]
    end

    rows += demand_rows

    rows.sort_by! { |visible, _spoken| I18n.transliterate(visible[1]) }

    {
      star: star,
      first: first,
      last: last,
      header: header,
      data: rows.map { |visible, _spoken| visible },
      actual: rows.map { |_visible, spoken| spoken },
    }
  end

  # Frase que o leitor de tela anuncia numa célula de dia: dia da semana no
  # singular, faixa de horas e sala. Os horários são inteiros (0..23), como no
  # to_shortlabel, então "11h às 13h" cobre o dado real.
  def class_schedule_spoken_allocation(allocation)
    label = "#{allocation.day}, " \
      "#{allocation.start_time}h às #{allocation.end_time}h"
    if allocation.room.present?
      label += ", #{I18n.t(
        "activerecord.attributes.allocation.room"
      )}: #{allocation.room}"
    end
    label
  end
end

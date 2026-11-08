# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# FormTemplate.sispos_sucupira_student_fields_config alimenta o botao
# "preencher com campos de aluno" do formulario de template (populate_field) e
# o seed 10.admissions.rb, que a suite nao carrega. Nenhum exemplo o chamava
# (#720). Cada entrada tem de virar um campo valido de formulario de inscricao.
RSpec.describe Admissions::FormTemplate, ".sispos_sucupira_student_fields_config", type: :model do
  let(:configuracao) { Admissions::FormTemplate.sispos_sucupira_student_fields_config }

  it "comeca pelo texto de introducao em HTML" do
    expect(configuracao.first).to include(
      name: I18n.t("active_scaffold.admissions/form_template.generate_fields.initial_text"),
      field_type: Admissions::FormField::HTML
    )
  end

  it "liga o CPF ao atributo do aluno" do
    cpf = configuracao.find do |campo|
      campo[:name] == I18n.t("active_scaffold.admissions/form_template.generate_fields.cpf")
    end

    expect(cpf[:field_type]).to eq(Admissions::FormField::STUDENT_FIELD)
    expect(JSON.parse(cpf[:configuration])).to include("field" => "cpf")
  end

  it "monta campos que um formulario de inscricao aceita gravar" do
    template = FactoryBot.create(:form_template, template_type: Admissions::FormTemplate::ADMISSION_FORM)

    configuracao.each_with_index do |atributos, ordem|
      template.fields.create!(atributos.merge(order: ordem))
    end

    expect(template.fields.count).to eq(configuracao.size)
    expect(template.fields.where(field_type: Admissions::FormField::STUDENT_FIELD)).to exist
  end
end

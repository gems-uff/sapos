# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Cantos da configuracao de campo de formulario sem cobertura (#720): JSON
# invalido na configuracao (o campo e montado por JS, entao so chega assim por
# requisicao forjada ou dado antigo), tipo de campo fora do template de
# consolidacao, contagem de selecao invertida, condicao incompleta, e a trava
# de ERB (#684) quando o historico tem versao de outro tipo ou JSON invalido.
RSpec.describe Admissions::FormField, "cantos da configuracao", type: :model do
  def erros(campo)
    campo.valid?
    campo.errors.details.transform_values { |lista| lista.map { |e| e[:error] } }
  end

  describe "configuracao com JSON invalido" do
    it "recusa a gravacao com invalid_format" do
      campo = FactoryBot.build(:form_field, field_type: Admissions::FormField::SELECT, configuration: "{")

      expect(erros(campo)[:configuration]).to include(:invalid_format)
    end

    it "devolve lista vazia para os valores" do
      campo = FactoryBot.build(:form_field, field_type: Admissions::FormField::SELECT, configuration: "{")

      expect(campo.get_values("values")).to eq([])
    end

    it "devolve [false] nos valores de template" do
      campo = FactoryBot.build(:form_field, field_type: Admissions::FormField::CODE, configuration: "{")

      expect(campo.template_values).to eq([false])
    end

    # A trava de ERB tambem le a configuracao e acusa o mesmo erro; o
    # ActiveModel guarda um so.
    it "recusa um campo de formula com invalid_format" do
      campo = FactoryBot.build(:form_field, field_type: Admissions::FormField::CODE, configuration: "{")

      expect(erros(campo)[:configuration]).to eq([:invalid_format])
    end
  end

  it "recusa campo de entrada num template de consolidacao" do
    template = FactoryBot.create(:form_template, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM)
    campo = FactoryBot.build(:form_field, form_template: template, field_type: Admissions::FormField::STRING)

    expect(erros(campo)[:base]).to include(:invalid_consolidation_field)
  end

  it "recusa selecao minima maior que a maxima" do
    campo = FactoryBot.build(
      :form_field, field_type: Admissions::FormField::COLLECTION_CHECKBOX,
      configuration: JSON.dump("values" => ["a", "b"], "minselection" => "3", "maxselection" => "1")
    )

    expect(erros(campo)[:base]).to include(:selection_count_error)
  end

  it "aceita selecao minima maior quando a maxima e zero (sem limite)" do
    campo = FactoryBot.build(
      :form_field, field_type: Admissions::FormField::COLLECTION_CHECKBOX,
      configuration: JSON.dump("values" => ["a", "b"], "minselection" => "3", "maxselection" => "0")
    )

    expect(erros(campo)[:base].to_a).not_to include(:selection_count_error)
  end

  describe "condicao de campo de formula incompleta" do
    def campo_com_condicao(condicao)
      template = FactoryBot.create(:form_template, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM)
      FactoryBot.build(
        :form_field, form_template: template, field_type: Admissions::FormField::CODE,
        configuration: JSON.dump("template_type" => "Liquid", "code" => "1", "condition" => condicao)
      )
    end

    it "acusa o campo em branco" do
      campo = campo_com_condicao("mode" => Admissions::FormCondition::CONDITION, "field" => "")

      expect(erros(campo)[:base]).to include(:condition_blank_field_error)
    end

    it "acusa o campo inexistente, citando o nome" do
      campo = campo_com_condicao("mode" => Admissions::FormCondition::CONDITION, "field" => "Campo Fantasma")

      expect(erros(campo)[:base]).to include(:condition_invalid_name_error)
      expect(campo.errors.full_messages.join).to include("Campo Fantasma")
    end

    it "acusa o modo em branco" do
      campo = campo_com_condicao("mode" => "")

      expect(erros(campo)[:base]).to include(:condition_blank_mode_error)
    end
  end

  # A trava procura no historico uma versao com o mesmo template ERB. Uma
  # versao de outro tipo de campo nao conta: o campo que vira formula ERB e
  # recusado como template novo.
  it "recusa converter em formula ERB um campo que antes era de selecao" do
    campo = FactoryBot.create(
      :form_field, field_type: Admissions::FormField::SELECT, configuration: JSON.dump("values" => ["a"])
    )
    campo.update!(name: "Campo Renomeado")
    template = FactoryBot.create(:form_template, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM)
    campo.assign_attributes(
      form_template: template, field_type: Admissions::FormField::CODE,
      configuration: JSON.dump("template_type" => "ERB", "code" => "<%= 1 %>")
    )

    expect(campo.paper_trail.previous_version.template_values).to eq([false])
    expect(erros(campo)[:base]).to include(:cannot_create_new_erb_template)
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Textos da interface (issue de texto).
RSpec.describe "Textos do processo seletivo", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "texts_admin@ic.uff.br")
    @template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
  end

  it "a edição do formulário mostra as setas de ordem" do
    get edit_form_template_path(@template)
    expect(response.body).to include("fa-arrow-up")
  end

  it "o tooltip das setas não traz código Ruby", pending: "issue #776" do
    get edit_form_template_path(@template)
    expect(response.body).not_to include('#{I18n.t(')
    expect(response.body).not_to include("Translation missing")
  end

  it "a exigência de linha não fala em caracteres", pending: "issue #776" do
    config = Admissions::RankingConfig.new(name: "x")
    config.valid?
    expect(config.errors.full_messages.join).not_to include("caracteres")
  end

  it "a mensagem de área do professor continua a frase", pending: "issue #776" do
    errors = ProfessorResearchLine.new.errors
    errors.add(:professor, :professor_area)
    expect(errors.full_messages.first).not_to start_with("Professor Tem")
  end
end

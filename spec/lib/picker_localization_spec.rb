# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O bridge de datas do active_scaffold monta os regionais do jQuery UI lendo o
# I18n com translate! -- a versao que levanta em chave faltando -- e o resgate
# interno dele re-levanta quando o locale e o da aplicacao. Esse texto nao vai
# para a pagina: ele e interpolado em date_picker_bridge.js.erb, um asset. Uma
# chave faltando, portanto, nao aparece como tela quebrada na suite; aparece
# como assets:precompile falhando na hora de subir a versao.
#
# Cada minor do active_scaffold pode exigir chave nova aqui: a 4.2 acrescentou
# os prompts de milissegundo e microssegundo aos que ja existiam.
RSpec.describe "jQuery UI picker localization" do
  let(:localization) { ActiveScaffold::Bridges[:date_picker].localization }

  it "builds without raising for the application locale" do
    expect(I18n.locale.to_s).to eq "pt-BR"
    expect { localization }.not_to raise_error
  end

  it "declares the regional of the application locale" do
    expect(localization).to include("$.datepicker.regional['pt-BR']")
    expect(localization).to include("$.timepicker.regional['pt-BR']")
  end

  it "carries every prompt the timepicker addon reads" do
    expect(localization).to include("hourText")
    expect(localization).to include("minuteText")
    expect(localization).to include("secondText")
    expect(localization).to include("millisecText")
    expect(localization).to include("microsecText")
  end

  it "carries the prompts translated, not the key name" do
    expect(localization).to include("Milissegundo")
    expect(localization).to include("Microssegundo")
  end

  # Sem estas o bridge ainda monta, mas registra "Missing date picker
  # localization" no log e o widget fica com os defaults em ingles.
  it "carries the options that keep the widget in Portuguese" do
    expect(localization).to include("Fechar")
    expect(localization).to include("Sem")
  end

  it "starts the week on the day the Brazilian calendar starts" do
    expect(localization).to match(/"firstDay":0/)
  end
end

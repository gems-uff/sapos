# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A reconstrucao dos credenciamentos pelo paper_trail separa as versoes que nao
# consegue ler, e nenhum exemplo montava uma (#720): object que nao e Hash,
# estado sem data de inicio e data em texto invalido. A versao ilegivel nao
# vira periodo e fica listada para o mantenedor conferir.
RSpec.describe AdvisementAuthorizationHistory, "versoes ilegiveis", type: :model do
  before(:each) do
    @professor = FactoryBot.create(:professor)
    @level = FactoryBot.create(:level)
  end

  def destroy_version(object)
    PaperTrail::Version.create!(
      item_type: "AdvisementAuthorization", item_id: 987_654, event: "destroy",
      created_at: Time.zone.local(2020, 5, 1, 12), object: object
    )
  end

  def rebuild
    AdvisementAuthorizationHistory.new.rebuild!
  end

  it "separa a versao cujo object nao e um Hash" do
    version = destroy_version("--- texto solto\n")

    history = rebuild

    expect(history.unreadable_version_ids).to eq([version.id])
    expect(AdvisementAuthorization.count).to eq(0)
  end

  it "separa a versao sem data de inicio, nem no ciclo nem no estado" do
    version = destroy_version(PaperTrail.serializer.dump(
      "professor_id" => @professor.id, "level_id" => @level.id
    ))

    history = rebuild

    expect(history.unreadable_version_ids).to eq([version.id])
    expect(history.inserted).to eq(0)
  end

  it "separa a versao com data de criacao em texto invalido" do
    version = destroy_version(PaperTrail.serializer.dump(
      "professor_id" => @professor.id, "level_id" => @level.id, "created_at" => "2020-13-45 10:00:00"
    ))

    history = rebuild

    expect(history.unreadable_version_ids).to eq([version.id])
    expect(AdvisementAuthorization.count).to eq(0)
  end

  # Controle: o mesmo estado com data legivel vira um periodo encerrado.
  it "reconstroi o periodo quando a data de criacao e legivel" do
    destroy_version(PaperTrail.serializer.dump(
      "professor_id" => @professor.id, "level_id" => @level.id, "created_at" => "2020-01-10 10:00:00"
    ))

    history = rebuild

    expect(history.unreadable_version_ids).to be_empty
    expect(AdvisementAuthorization.pluck(:start_date, :end_date))
      .to eq([[Date.new(2020, 1, 10), Date.new(2020, 5, 1)]])
  end
end

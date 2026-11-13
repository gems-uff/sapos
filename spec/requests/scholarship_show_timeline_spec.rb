# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A linha do tempo do detalhe da bolsa (#720): nenhum exemplo fazia GET
# /scholarships/:id, entao scholarship_timeline_show_column, o TimelineWidget
# e o monthyear2 que formata as datas dos eventos nunca rodavam. A bolsa
# cancelada antes do fim tem reproducao propria (#728) e fica fora daqui.
RSpec.describe "Detalhe da bolsa com a linha do tempo", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_bolsa_timeline@ic.uff.br", "Adm"
    )
    @level = FactoryBot.create(:level)
    @matricula = FactoryBot.create(
      :enrollment, enrollment_number: "M-TL", level: @level,
      student: FactoryBot.create(:student, name: "Aluno Timeline"),
      admission_date: Date.new(2022, 1, 1)
    )
  end

  def bolsa(end_date:)
    FactoryBot.create(
      :scholarship, scholarship_number: "B-TL", level: @level,
      start_date: Date.new(2022, 3, 1), end_date: end_date
    )
  end

  def script_da_linha_do_tempo(scholarship)
    html = Nokogiri::HTML(response.body)
    expect(html.css("div.fulltimeline div#scholarship_timeline_#{scholarship.id}")).not_to be_empty
    html.css("dd.timeline-view script").first.text
  end

  it "desenha a bolsa e a duracao, com as datas por extenso" do
    scholarship = bolsa(end_date: Date.new(2024, 2, 1))
    FactoryBot.create(
      :scholarship_duration, scholarship: scholarship, enrollment: @matricula,
      start_date: Date.new(2022, 3, 1), end_date: Date.new(2023, 2, 1)
    )

    get scholarship_path(scholarship)

    expect(response).to have_http_status(:ok)
    script = script_da_linha_do_tempo(scholarship)
    expect(script).to include("var events_#{scholarship.id} = [")
    expect(script).to include("title: 'M-TL - Aluno Timeline: Março/2022 - Fevereiro/2023'")
    expect(script).to include("dates: [new Date(2022, 2, 1),new Date(2023, 1, 28)]")
    expect(script).to include('attrs: {"fill":"#00AA00","stroke":"#00AA00"}')
    expect(script).to include("title: 'B-TL: Março/2022 - Fevereiro/2024'")
    # Um mes de folga de cada lado: de 01/02/2022 a 29/03/2024, mais que 700 dias.
    expect(script).to include("visibleSpan:  DAY_IN_MILLISECONDS * 700")
    expect(script).to include("startDate: new Date(2022, 1, 1)")
    expect(script).to include("endDate: new Date(2024, 2, 29)")
  end

  it "mostra a bolsa sem fim como presente e com o intervalo curto inteiro" do
    scholarship = bolsa(end_date: nil)

    get scholarship_path(scholarship)

    expect(response).to have_http_status(:ok)
    script = script_da_linha_do_tempo(scholarship)
    expect(script).to include("title: 'B-TL: Março/2022 - Presente'")
    expect(script).to include("var events_#{scholarship.id} = [{")
  end

  it "encurta a janela visivel quando a bolsa dura menos de 700 dias" do
    scholarship = bolsa(end_date: Date.new(2022, 5, 1))

    get scholarship_path(scholarship)

    script = script_da_linha_do_tempo(scholarship)
    # De 01/02/2022 a 30/06/2022.
    expect(script).to include("visibleSpan:  DAY_IN_MILLISECONDS * 149")
  end
end

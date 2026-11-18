# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A tabela de "Calcular ranking" segue a ordem das colunas de ordenação; com
# duas passadas a posição não acompanha a nota, e a tabela sai fora de ordem.
RSpec.describe "Ordem da tabela de Calcular ranking", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "ranking_order_admin@ic.uff.br")
    template = create_admission_template(
      "Inscrição", { "nota" => Admissions::FormField::NUMBER, "cota" => Admissions::FormField::STRING }
    )
    @process = create_closed_admission_process(template, simple_url: "ranking-order")
    quota = FactoryBot.create(:ranking_machine, name: "Cota")
    quota.update!(form_condition: Admissions::FormCondition.create!(
      mode: Admissions::FormCondition::CONDITION, field: "cota",
      condition: Admissions::FormCondition::EQUALS, value: "sim"
    ))
    general = FactoryBot.create(:ranking_machine, name: "AC")
    @ranking = Admissions::RankingConfig.new(
      name: "Seleção",
      behavior_on_invalid_condition: Admissions::RankingConfig::IGNORE_CONDITION,
      behavior_on_invalid_ranking: Admissions::RankingConfig::IGNORE_RANKING
    )
    @ranking.ranking_columns.build(name: "nota", order: Admissions::RankingColumn::DESC)
    @ranking.ranking_processes.build(ranking_machine: quota, vacancies: 1, order: 1, step: 1)
    @ranking.ranking_processes.build(ranking_machine: general, vacancies: nil, order: 2, step: 2)
    @ranking.save!
    @process_ranking = FactoryBot.create(
      :admission_process_ranking, admission_process: @process, ranking_config: @ranking, order: 1
    )
    @higher_grade = create_application(@process, fields: { "nota" => "9", "cota" => "nao" })
    @quota = create_application(@process, fields: { "nota" => "8", "cota" => "sim" })
    post calculate_ranking_admission_process_path(@process),
      params: { admission_process_ranking_id: @process_ranking.id }, xhr: true
  end

  def position(application)
    Admissions::AdmissionRankingResult.find_by!(
      admission_application: application, ranking_config: @ranking
    ).filled_position.value
  end

  it "classifica a cota em 1º na primeira passada e a nota maior em 2º na segunda" do
    expect(position(@quota)).to eq("1")
    expect(position(@higher_grade)).to eq("2")
    expect(response.body).to include(@higher_grade.token)
  end

  it "lista pela posição", pending: "issue #766" do
    expect(response.body.index(@quota.token)).to be < response.body.index(@higher_grade.token)
  end
end

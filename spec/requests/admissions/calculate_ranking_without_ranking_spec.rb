# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# "Calcular ranking" sem ranking escolhido chama generate_ranking em nil.
RSpec.describe "Calcular ranking sem ranking", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "no_ranking_admin@ic.uff.br")
    template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(template, simple_url: "no-ranking")
  end

  it "calcula sem erro com um ranking escolhido" do
    ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
    chosen = FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: ranking, order: 1)
    post calculate_ranking_admission_process_path(@process), params: { admission_process_ranking_id: chosen.id }
    expect(flash[:error]).to be_nil
  end

  it "explica a falta de ranking sem notificar exceção", pending: "issue #774" do
    expect(ExceptionNotifier).not_to receive(:notify_exception)
    post calculate_ranking_admission_process_path(@process)
    expect(flash[:error].to_s).not_to include("undefined method")
  end
end

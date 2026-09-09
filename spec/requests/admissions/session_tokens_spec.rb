# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Processo com require_session so deixa abrir a inscricao no navegador que a
# recuperou, e a prova disso e o token guardado em `session[:admission_tokens]`.
# O `add_token_to_session` grava do mesmo jeito que o active_scaffold grava a
# busca: cria a chave no topo na primeira vez e daí em diante muta o Set em
# lugar. Enquanto o activerecord-session_store nao enxergava mutacao em lugar,
# so o primeiro token sobrevivia -- o candidato que recuperava uma segunda
# inscricao no mesmo navegador levava "acesso nao autorizado" na cara.
#
# E o mesmo defeito da #660, noutro assunto: por isso a correcao e do store, e
# nao da lista. Ver config/initializers/fix_session_store_dirty_tracking.rb.
RSpec.describe "Admissions tokens na sessao", type: :request do
  before(:each) do
    template = FactoryBot.create(:form_template, name: "Inscrição")
    @applications = 2.times.map do |i|
      process = FactoryBot.create(
        :admission_process, name: "Processo #{i}", simple_url: "processo-#{i}",
        form_template: template, require_session: true,
        start_date: Date.today - 10.days,
        end_date: Date.today + 10.days,
        edit_date: Date.today + 20.days
      )
      FactoryBot.create(
        :admission_application, admission_process: process,
        email: "candidato#{i}@example.com",
        filled_form: FactoryBot.create(
          :filled_form, form_template: template, is_filled: true
        )
      )
    end
  end

  def recover(application)
    post find_admissions_path, params: {
      admissions_admission_application: {
        token: application.token, email: application.email
      }
    }
  end

  def open_application(application)
    get admission_apply_path(
      admission_id: application.admission_process.simple_id,
      id: application.token
    )
  end

  # A leitura tem de vir numa requisicao POSTERIOR: dentro da requisicao que
  # gravou, o Set ja esta em memoria com os dois tokens mesmo quando nada foi
  # gravado. E a travessia entre requisicoes que o defeito quebrava.
  it "guarda o token de cada inscricao recuperada" do
    recover @applications[0]
    recover @applications[1]

    open_application @applications[0]

    expect(session[:admission_tokens]).to contain_exactly(
      @applications[0].token, @applications[1].token
    )
  end

  it "abre a segunda inscricao recuperada na mesma sessao" do
    recover @applications[0]
    recover @applications[1]

    open_application @applications[1]

    expect(response).to have_http_status(:ok)
    expect(flash[:alert]).to be_nil
  end

  it "continua barrando inscricao que nao foi recuperada neste navegador" do
    recover @applications[0]

    open_application @applications[1]

    expect(response).to redirect_to(admissions_path)
    expect(flash[:alert]).to be_present
  end
end

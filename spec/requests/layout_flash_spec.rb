# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Estes falham. O layout passou a imprimir todo o flash, chave por chave, acima
# da navegacao -- antes imprimia so `notice`. Mas ha telas que ja imprimem a
# propria mensagem, e chaves de flash que nao sao mensagem: o layout vale para
# o sistema inteiro, inclusive para as telas publicas de login e de inscricao.
# Controle de cada um: com o layout anterior, passa.
RSpec.describe "Mensagens de flash no layout", type: :request do
  # A tela de login imprime flash[:alert] em #error_login; o layout agora o
  # imprime de novo, e quem erra a senha le a recusa duas vezes.
  it "mostra a recusa do login uma vez so" do
    create_confirmed_user([FactoryBot.create(:role_administrador)], "admin@ic.uff.br")

    post user_session_path,
      params: { user: { email: "admin@ic.uff.br", password: "senha-errada" } }

    recusa = Nokogiri::HTML(response.body).at_css("#error_login").text.strip
    expect(recusa).to be_present
    expect(response.body.scan(recusa).size).to eq(1)
  end

  describe "recusa da recuperacao de inscricao" do
    before(:each) do
      template = FactoryBot.create(:form_template, name: "Inscrição")
      processo = FactoryBot.create(
        :admission_process, name: "Processo", simple_url: "processo-flash",
        form_template: template, require_session: true,
        start_date: Date.today - 10.days, end_date: Date.today + 10.days,
        edit_date: Date.today + 20.days
      )
      @inscricao = FactoryBot.create(
        :admission_application, admission_process: processo,
        email: "candidato@example.com",
        filled_form: FactoryBot.create(:filled_form, form_template: template, is_filled: true)
      )

      post find_admissions_path, params: {
        admissions_admission_application: {
          token: @inscricao.token, email: "outro@example.com"
        }
      }
      follow_redirect!
    end

    # flash[:recover] nao e mensagem: e o Hash com e-mail e codigo de
    # identificacao que o formulario usa para se repreencher sem por a
    # credencial na URL (Admissions::AdmissionsController#recover_form_values).
    # O layout o imprime como texto -- `{"email" => ..., "token" => ...}` --
    # numa tela publica. O codigo ja estava no HTML, como valor do campo do
    # formulario; o que muda e que ele passa a aparecer escrito na pagina.
    it "nao escreve na pagina o codigo de identificacao" do
      texto_visivel = Nokogiri::HTML(response.body).text

      expect(texto_visivel).not_to include(@inscricao.token)
    end

    it "mostra a recusa uma vez so" do
      recusa = I18n.t("errors.admissions.application_not_found")

      expect(response.body.scan(recusa).size).to eq(1)
    end
  end
end

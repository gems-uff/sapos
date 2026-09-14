# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Consolidar fase e calcular ranking são as duas ações que, em vez de deixar a
# exceção subir até o middleware, a capturam, avisam por
# ExceptionNotifier.notify_exception e devolvem a mensagem ao usuário no flash.
# Esses dois rescue eram as únicas linhas da aplicação que chamam a API do
# exception_notification e nunca rodavam na suíte -- o ambiente de teste não
# monta o middleware, e nenhum spec forçava o erro.
#
# O notificador não é substituído por dublê: and_call_original deixa a chamada
# real acontecer (sem notifier registrado ela não envia nada) para que a
# assinatura do método seja exercitada de verdade, e o spy só confere que ela
# ocorreu com a exceção certa.
RSpec.describe "Admissions::AdmissionProcesses: erros notificados", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "notify_admin@ic.uff.br")
    sign_in @admin
    @process = FactoryBot.create(
      :admission_process, name: "Processo Notificado", simple_url: "notify-mestrado"
    )
    allow(ExceptionNotifier).to receive(:notify_exception).and_call_original
  end

  describe "consolidar fase" do
    it "notifica a exceção e devolve o erro no flash quando a fase não pertence ao processo" do
      # A ação monta a lista de fases do processo e procura a pedida; com uma
      # fase estranha o índice vem nil e phases[nil] levanta TypeError dentro
      # do método, que é o que o rescue de nível de método captura.
      stranger = FactoryBot.create(:admission_phase, name: "Fase de Outro Processo")

      post consolidate_phase_admission_process_path(@process),
        params: { consolidate_phase_id: stranger.id }

      expect(ExceptionNotifier).to have_received(:notify_exception)
        .with(an_instance_of(TypeError))
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to start_with("Erro ao consolidar fase:")
    end
  end

  describe "calcular ranking" do
    it "notifica a exceção e devolve o erro no flash quando o ranking não existe" do
      # where(...).first devolve nil e nil.generate_ranking levanta NoMethodError.
      post calculate_ranking_admission_process_path(@process),
        params: { admission_process_ranking_id: 0 }

      expect(ExceptionNotifier).to have_received(:notify_exception)
        .with(an_instance_of(NoMethodError))
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to start_with("Erro ao calcular ranking:")
    end
  end
end

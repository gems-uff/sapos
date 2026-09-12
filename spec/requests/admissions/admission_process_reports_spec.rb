# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Ranking e relatório configurável pela tela do processo (#681): calcular um
# ranking e mostrar as posições; guardar na sessão uma configuração de
# relatório e vê-la refletida no PDF e na planilha; e descartá-la.
RSpec.describe "Admissions::AdmissionProcesses: ranking e relatório configurável", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "reports_admin@ic.uff.br")
    sign_in @admin

    @template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(@template, simple_url: "reports-request")
    @ana = create_application(@process, name: "Ana", fields: { "nota" => "9" })
    @bia = create_application(@process, name: "Bia", fields: { "nota" => "7" })
    @ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
    @ranking.ranking_columns.first.update!(order: Admissions::RankingColumn::DESC)
    @process_ranking = FactoryBot.create(
      :admission_process_ranking, admission_process: @process, ranking_config: @ranking, order: 1
    )
  end

  describe "POST calculate_ranking" do
    it "calcula as posições e redireciona para a lista" do
      post calculate_ranking_admission_process_path(@process),
        params: { admission_process_ranking_id: @process_ranking.id }

      expect(response).to redirect_to(admission_processes_path)
      expect(flash[:error]).to be_nil
      positions = Admissions::AdmissionRankingResult.where(ranking_config: @ranking).to_h do |result|
        [result.admission_application_id, result.filled_position.value]
      end
      expect(positions).to eq({ @ana.id => "1", @bia.id => "2" })
    end

    it "mostra a tabela de posições quando pedido por xhr" do
      post calculate_ranking_admission_process_path(@process),
        params: { admission_process_ranking_id: @process_ranking.id }, xhr: true

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@ana.token)
      expect(response.body).to include(@bia.token)
      expect(response.body).to include("Geral")
    end

    it "fecha o formulário e devolve o erro quando o cálculo falha por xhr" do
      allow(ExceptionNotifier).to receive(:notify_exception).and_call_original
      post calculate_ranking_admission_process_path(@process),
        params: { admission_process_ranking_id: 0 }, xhr: true
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action_link.close()")
    end
  end

  describe "relatório configurável" do
    def report_params(**extra)
      {
        record: {
          name: "Relatório da sessão",
          group_column_tabular: Admissions::AdmissionReportConfig::COLUMN,
          hide_empty_sections: "1",
          show_partial_candidates: "1",
        }.merge(extra),
      }
    end

    it "abre o formulário de configuração por html e por xhr" do
      get custom_report_admission_processes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("active_scaffold.admissions/admission_process.custom_report.title"))

      get custom_report_admission_processes_path, xhr: true
      expect(response).to have_http_status(:ok)
    end

    it "guarda a configuração na sessão e a aplica nos relatórios seguintes" do
      post custom_report_generate_admission_processes_path, params: report_params
      expect(response).to redirect_to(admission_processes_path)
      expect(flash[:info]).to eq("Relatório configurado")
      expect(session[:admission_report_config]).to include("name" => "Relatório da sessão")

      # Modo coluna: cada seção ganha uma coluna de título, que a planilha
      # padrão (modo mesclar) não tem.
      get complete_xls_admission_process_path(@process, format: :xlsx)
      expect(response).to have_http_status(:ok)
      cells = xlsx_representation(response.body)
      expect(cells).to include("=#{Admissions::AdmissionReportGroup::FIELD}")
      expect(cells).to include("Ana")

      get complete_pdf_admission_process_path(@process, format: :pdf)
      expect(response).to have_http_status(:ok)
      expect(pdf_representation(response.body)).to include("Ana")

      get short_pdf_admission_process_path(@process, format: :pdf)
      expect(response).to have_http_status(:ok)
    end

    it "mantém o formulário aberto com 'Usar configuração' e responde por xhr e iframe" do
      post custom_report_generate_admission_processes_path, params: report_params(dont_close: "1").merge(dont_close: "1")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Relatório configurado")

      post custom_report_generate_admission_processes_path, params: report_params, xhr: true
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action_link.close()")

      post custom_report_generate_admission_processes_path, params: report_params.merge(iframe: true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("parent")
    end

    it "recusa configuração inválida sem gravar na sessão" do
      post custom_report_generate_admission_processes_path,
        params: { record: { name: "", group_column_tabular: "inválido" } }
      expect(response).to have_http_status(:ok)
      expect(session[:admission_report_config]).to be_nil
      expect(response.body).to include(I18n.t("active_scaffold.admissions/admission_process.custom_report.title"))
    end

    it "reset_report descarta a configuração da sessão" do
      post custom_report_generate_admission_processes_path, params: report_params
      expect(session[:admission_report_config]).to be_present

      post reset_report_admission_processes_path
      expect(response).to redirect_to(admission_processes_path)
      expect(session[:admission_report_config]).to be_nil

      post reset_report_admission_processes_path, params: { on_form: "1" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("active_scaffold.admissions/admission_process.custom_report.title"))

      get reset_report_admission_processes_path, xhr: true
      expect(response).to have_http_status(:ok)

      post reset_report_admission_processes_path, params: { iframe: true }
      expect(response.body).to include("parent")
    end

    it "a tela de detalhe do processo carrega a configuração da sessão" do
      post custom_report_generate_admission_processes_path, params: report_params
      get admission_process_path(@process)
      expect(response).to have_http_status(:ok)
    end
  end
end

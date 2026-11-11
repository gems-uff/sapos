# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O código de acesso da carta de recomendação é a credencial do recomendador:
# com ele a página pública da carta abre e aceita alteração enquanto o processo
# está aberto. O membro da comissão lê o que a carta diz pela tela da
# candidatura, e não precisa do código; quem gerencia o processo o vê como
# link, para preencher a carta em nome do recomendador.
RSpec.describe "Codigo de acesso da carta na lista de cartas", type: :request do
  before(:each) do
    role = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([role], "cartas-admin@example.com")
    allow(Notifier).to receive(:send_emails)
    workflow = AdmissionsWorkflowLoader.load(process_id: 3)
    @process = workflow.process
    homologacao, = workflow.phase_links.map(&:admission_phase)
    secretaria = workflow.committee_users[1].first
    @membro = workflow.committee_users[3].first

    @kim = apply_as_candidate(
      @process, name: "Kim", email: "kim@example.com", values: { "Linha de pesquisa" => "Linha 1" },
      letters: [{ name: "Rec Um", email: "rec-um@example.com", telephone: "2199" },
                { name: "Rec Dois", email: "rec-dois@example.com" }]
    )
    @kim.letter_requests.each do |carta|
      fill_letter_as_recommender(@process, carta, { "Relação com o candidato" => "Orientador", "Avaliação" => "Excelente" })
    end
    sign_in @admin
    consolidate_phase_as_staff(@process, nil)
    sign_out @admin
    sign_in secretaria
    submit_phase_form(
      @kim, homologacao, homologacao.shared_form, { "Homologação" => "Deferida" },
      mode: Admissions::AdmissionPhaseResult::SHARED
    )
    sign_out secretaria
    sign_in @admin
    consolidate_phase_as_staff(@process, homologacao)
    sign_out @admin
    @codigos = @kim.letter_requests.reload.map(&:access_token)
    expect(@codigos.size).to eq(2)
    expect(@kim.pendencies.where(user: @membro, status: Admissions::AdmissionPendency::PENDENT)).to be_present
  end

  def mostra_codigo?
    @codigos.any? { |codigo| response.body.include?(codigo) }
  end

  context "para o membro da comissao com pendencia na candidatura" do
    before(:each) { sign_in @membro }

    it "lista as cartas sem o codigo de acesso" do
      get letter_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rec Um", "Rec Dois")
      expect(mostra_codigo?).to be(false)
    end

    it "lista as cartas sem o codigo tambem na atualizacao da lista por XHR" do
      get letter_requests_path, xhr: true

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rec Um")
      expect(mostra_codigo?).to be(false)
    end

    # A busca da lista casa qualquer pedaço do texto: com o código entre as
    # colunas buscadas, a linha que sobra confirma o pedaço tentado.
    it "nao encontra a carta por um pedaco do codigo" do
      um = @kim.letter_requests.find_by!(name: "Rec Um")

      get letter_requests_path, params: { search: um.access_token[0, 6] }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Rec Um")
    end

    # Controle: a busca pelo nome do recomendador segue achando a carta.
    it "encontra a carta pelo nome do recomendador" do
      get letter_requests_path, params: { search: "Rec Um" }

      expect(response.body).to include("Rec Um")
      expect(response.body).not_to include("Rec Dois")
    end

    it "nao ordena a lista pelo codigo" do
      expect(Admissions::LetterRequestsController.active_scaffold_config.columns[:access_token].sortable?).to be(false)
    end

    # Controle: sem o código, o membro segue lendo o que a carta diz, pela
    # tela da candidatura em que tem a pendência.
    it "le o conteudo da carta pela tela da candidatura" do
      get edit_admission_application_path(@kim)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rec Um", "Excelente")
      expect(mostra_codigo?).to be(false)
    end
  end

  # Controle: quem gerencia o processo vê o código, como link para a página
  # pública da carta.
  it "mostra o codigo como link para quem gerencia o processo" do
    sign_in @admin

    get letter_requests_path

    expect(response).to have_http_status(:ok)
    @kim.letter_requests.each do |carta|
      expect(response.body).to include(
        admission_letter_path(admission_id: @process.simple_id, id: carta.access_token)
      )
    end
  end
end

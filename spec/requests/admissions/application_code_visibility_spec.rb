# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O código de identificação é a credencial do candidato: com ele e o e-mail, a
# página pública da inscrição abre e, no prazo de edição, aceita alteração. Os
# seis primeiros caracteres são o identificador, que basta para citar a
# candidatura. Quem gerencia o processo vê o código inteiro, para socorrer o
# candidato que o perdeu; o membro da comissão vê o identificador, e nenhuma
# busca lhe confirma o resto.
RSpec.describe "Codigo da inscricao nas telas internas", type: :request do
  before(:each) do
    role = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([role], "codigo-admin@example.com")
    allow(Notifier).to receive(:send_emails)
    @process, @kim, @membro = application_awaiting_committee(@admin)
    @codigo = @kim.token
    @segredo = @codigo[7..]
    expect(@kim.identifier).to eq(@codigo[0, 6])
  end

  def abrir(caminho, **opcoes)
    get caminho, **opcoes
    expect(response).to have_http_status(:ok), caminho
    response.body
  end

  def linhas
    Nokogiri::HTML(response.body).css("tr.record[data-refresh]").size
  end

  context "para o membro da comissao com pendencia na candidatura" do
    before(:each) { sign_in @membro }

    it "mostra o identificador, e nao o codigo, em cada tela que cita a candidatura" do
      telas = [
        admission_applications_path, admission_application_path(@kim), edit_admission_application_path(@kim),
        letter_requests_path, pendencies_path, filled_forms_path, admission_phase_results_path,
      ]

      telas.each do |tela|
        corpo = abrir(tela)
        expect(corpo).not_to include(@segredo), tela
      end
      expect(abrir(admission_applications_path)).to include(@kim.identifier)
      expect(abrir(letter_requests_path)).to include("Kim - #{@kim.identifier}")
    end

    it "nao encontra a candidatura por um pedaco do resto do codigo" do
      abrir(admission_applications_path, params: { search: { token: @segredo[0, 5] } })
      expect(linhas).to eq(0)

      abrir(admission_applications_path, params: { search: { token: @codigo[3, 8] } })
      expect(linhas).to eq(0)
    end

    # Controles: o identificador, inteiro ou em parte, e o código inteiro de
    # quem já o tem seguem achando.
    it "encontra a candidatura pelo identificador e pelo codigo inteiro" do
      [@kim.identifier, @kim.identifier[1, 4], @codigo].each do |termo|
        abrir(admission_applications_path, params: { search: { token: termo } })
        expect(linhas).to eq(1), termo
      end
    end

    it "nao encontra a candidatura pelo resto do codigo na busca do seletor" do
      corpo = abrir(browse_admission_applications_path, params: { search: @segredo[0, 5] })
      expect(corpo).not_to include("Kim")

      corpo = abrir(browse_admission_applications_path, params: { search: "Kim" })
      expect(corpo).to include("Kim - #{@kim.identifier}")
      expect(corpo).not_to include(@segredo)
    end
  end

  # Controle: quem gerencia o processo segue vendo o código inteiro na lista e
  # na ficha, e o identificador no rótulo.
  it "mostra o codigo inteiro a quem gerencia o processo" do
    sign_in @admin

    expect(abrir(admission_applications_path)).to include(@codigo)
    expect(abrir(admission_application_path(@kim))).to include(@codigo)
    expect(abrir(letter_requests_path)).to include("Kim - #{@kim.identifier}")
  end

  # A secretaria gerencia o processo sem gerenciar cada candidatura (lê e
  # altera, não apaga): é ela quem socorre o candidato que perdeu o código.
  context "para a secretaria" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_secretaria)], "codigo-secretaria@example.com")
    end

    it "mostra o codigo inteiro da inscricao na lista e na ficha" do
      expect(abrir(admission_applications_path)).to include(@codigo)
      expect(abrir(admission_application_path(@kim))).to include(@codigo)
    end

    it "mostra o codigo de acesso da carta, sem o link de quem gerencia a carta" do
      corpo = abrir(letter_requests_path)

      @kim.letter_requests.each do |carta|
        expect(corpo).to include(carta.access_token)
        expect(corpo).not_to include(admission_letter_path(admission_id: @process.simple_id, id: carta.access_token))
      end
    end
  end

  # A busca por campo da lista oferece comparadores às colunas de texto
  # (contém, não contém, começa com). A do código é um campo simples: o termo
  # casa com o identificador ou com o código inteiro, e mais nada.
  it "oferece na busca um campo simples para o codigo, sem comparador" do
    sign_in @admin

    corpo = abrir(show_search_admission_applications_path, xhr: true)

    expect(corpo).to include('name="search[token]"')
    expect(corpo).not_to include("search[token][opt]")
    expect(corpo).to include("search[name][opt]")
  end

  # O seletor de candidaturas lista o que a lista lista: as candidaturas em
  # que quem pede tem pendência.
  it "nao lista no seletor a candidatura de quem nao tem pendencia nela" do
    outro = FactoryBot.create(:professor)
    sem_pendencia = create_confirmed_user(
      [Role.find_by(id: Role::ROLE_PROFESSOR) || FactoryBot.create(:role_professor)],
      "codigo-outro-professor@example.com", "Outro Professor", professor: outro
    )

    sign_in sem_pendencia
    expect(abrir(browse_admission_applications_path, params: { search: "Kim" })).not_to include("Kim - ")

    sign_in @membro
    expect(abrir(browse_admission_applications_path, params: { search: "Kim" })).to include("Kim - #{@kim.identifier}")
  end
end

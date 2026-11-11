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
end

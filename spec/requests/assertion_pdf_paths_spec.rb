# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A declaracao em PDF so era gerada pelo caminho comum
# (assertion_authorization_spec.rb). Sem cobertura (#720): os links da ficha da
# matricula que escolhem a assinatura (sem assinatura, manual, QR code), a
# declaracao cuja consulta nao devolve linha para a matricula e o re-raise de
# outro erro de template.
RSpec.describe "Declaracao em PDF", type: :request do
  include_context "consulta somente-leitura na conexao do teste"

  before(:each) do
    @enrollment = FactoryBot.create(:enrollment, enrollment_number: "M-DECL-1")
    query = Query.new(
      name: "declaracao_por_matricula",
      sql: "select enrollment_number as matricula from enrollments where enrollment_number = :matricula_aluno"
    )
    query.params.build(name: "matricula_aluno", value_type: "String", default_value: "")
    query.save!
    @assertion = Assertion.create!(
      name: "Declaracao por matricula", query:,
      template_type: "Liquid", assertion_template: "Matricula: {{ matricula }}"
    )
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.decl@ic.uff.br", "Adm")
  end

  def gerar(matricula, assinatura: nil)
    if assinatura
      get override_signature_assertion_pdf_assertion_path(
        @assertion, signature_type: assinatura, query_params: { matricula_aluno: matricula }, format: :pdf
      )
    else
      get assertion_pdf_assertion_path(@assertion, query_params: { matricula_aluno: matricula }, format: :pdf)
    end
  end

  describe "assinatura escolhida no link" do
    it "com QR code gera o PDF e registra o documento para validacao" do
      expect { gerar("M-DECL-1", assinatura: "qr_code") }.to change { Report.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(Report.last.file_name).to end_with("Declaracao por matricula.pdf")
    end

    it "sem assinatura gera o PDF sem registrar documento" do
      expect { gerar("M-DECL-1", assinatura: "no_signature") }.not_to change { Report.count }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    it "manual gera o PDF sem registrar documento" do
      expect { gerar("M-DECL-1", assinatura: "manual") }.not_to change { Report.count }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end
  end

  it "volta com aviso quando a consulta nao acha a matricula" do
    gerar("M-INEXISTENTE", assinatura: "no_signature")

    expect(response).to redirect_to(root_path)
    expect(flash[:warning]).to eq(
      I18n.t("activerecord.errors.models.assertion.empty_query", matricula: "M-INEXISTENTE")
    )
  end

  # Defesa: so o EmptyQueryException vira aviso; outro erro do template sobe.
  it "deixa subir outro erro do template" do
    allow_any_instance_of(Assertion).to receive(:format_text).and_raise(ArgumentError, "outro erro")

    gerar("M-DECL-1")

    expect(response).to have_http_status(:internal_server_error)
    expect(flash[:warning]).to be_nil
  end
end

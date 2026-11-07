# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Caminhos do EnrollmentsController que nenhum exemplo percorria (#720): os
# links da ficha da matricula que escolhem a assinatura do historico e do
# boletim, o "criar usuarios" sem js (com e sem usuario criado) e o aviso ao
# professor quando a edicao da matricula muda a nota de uma inscricao.
RSpec.describe "Matriculas: documentos, usuarios e notas", type: :request do
  include_context "consulta somente-leitura na conexao do teste"

  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.matriculas@ic.uff.br", "Adm")
    allow(Notifier).to receive(:send_emails)
  end

  describe "assinatura escolhida no link da ficha" do
    before(:each) { @enrollment = FactoryBot.create(:enrollment) }

    it "historico com QR code gera o PDF e registra o documento" do
      expect do
        get override_signature_transcript_pdf_enrollment_path(@enrollment, signature_type: "qr_code", format: :pdf)
      end.to change { Report.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    it "boletim com QR code gera o PDF e registra o documento" do
      expect do
        get override_signature_grades_report_pdf_enrollment_path(@enrollment, signature_type: "qr_code", format: :pdf)
      end.to change { Report.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    # Controle: sem QR code nao ha documento a registrar.
    it "boletim sem assinatura gera o PDF sem registrar documento" do
      expect do
        get override_signature_grades_report_pdf_enrollment_path(@enrollment, signature_type: "no_signature", format: :pdf)
      end.not_to change { Report.count }

      expect(response).to have_http_status(:ok)
    end
  end

  # A matricula ja cria o usuario no after_create quando a situacao permite;
  # o botao alcanca a que nasceu numa situacao sem usuario e mudou depois.
  describe "POST create_users sem js" do
    before(:each) do
      FactoryBot.create(:role_aluno)
      @status = FactoryBot.create(:enrollment_status, user: false)
    end

    def criar_usuarios
      post create_users_enrollments_path, params: { add_option: "default" }
    end

    it "avisa quando nenhum usuario e criado" do
      FactoryBot.create(:enrollment, enrollment_status: @status, student: FactoryBot.create(:student, email: nil))
      @status.update_column(:user, true)

      expect { criar_usuarios }.not_to change { User.count }

      # O return_to_main leva o add_option do formulario para a URL da lista.
      expect(response).to redirect_to(enrollments_path(add_option: "default"))
      expect(flash[:error]).to eq("Nenhum usuário criado")
      expect(flash[:info]).to be_nil
    end

    it "cria o usuario do aluno e volta para a lista com a contagem" do
      student = FactoryBot.create(:student, email: "aluno.novo.usuario@ic.uff.br")
      FactoryBot.create(:enrollment, enrollment_status: @status, student:)
      @status.update_column(:user, true)

      expect { criar_usuarios }.to change { User.count }.by(1)

      expect(response).to redirect_to(enrollments_path(add_option: "default"))
      expect(flash[:info]).to eq("1 usuário criado")
      expect(flash[:error]).to be_nil
      expect(student.reload.user.email).to eq("aluno.novo.usuario@ic.uff.br")
    end

    # Defesa: o formulario new_users nunca e multipart, a tela nao pede iframe.
    it "com iframe=true responde ao frame pai" do
      post create_users_enrollments_path, params: { iframe: "true", add_option: "default" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("with(window.parent)")
    end
  end

  describe "edicao da matricula com inscricao em disciplina" do
    before(:each) do
      @enrollment = FactoryBot.create(:enrollment)
      com_nota = FactoryBot.create(:course, course_type: FactoryBot.create(:course_type, has_score: true))
      @inscricao = FactoryBot.create(
        :class_enrollment, enrollment: @enrollment, course_class: FactoryBot.create(
          :course_class, course: com_nota, professor: FactoryBot.create(:professor, email: "prof.nota@ic.uff.br")
        )
      )
    end

    def atualizar(campos)
      patch enrollment_path(@enrollment), params: {
        record: { class_enrollments: { @inscricao.id.to_s => campos.merge(id: @inscricao.id) } },
      }
    end

    # O before_update_save do controller avisa o professor; o aviso ao aluno
    # sai depois, do callback do modelo.
    it "avisa o professor quando a nota muda" do
      enviados = []
      allow(Notifier).to receive(:send_emails) { |notifications:| enviados.concat(notifications) }

      atualizar(situation: ClassEnrollment::APPROVED, grade: "8.5")

      expect(response).to redirect_to(enrollments_path)
      expect(@inscricao.reload.grade).to eq(85)
      ao_professor = enviados.select { |m| m[:to] == "prof.nota@ic.uff.br" }
      expect(ao_professor.size).to eq(1)
      expect(ao_professor.first[:body]).to include("-Nota: 8.5*")
    end

    it "nao avisa quando a inscricao nao muda" do
      atualizar(situation: @inscricao.situation)

      expect(response).to redirect_to(enrollments_path)
      expect(Notifier).not_to have_received(:send_emails)
    end
  end
end

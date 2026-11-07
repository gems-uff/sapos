# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O mapeamento de candidato em aluno so tinha coberta a gravacao, e com a
# resposta trocada por head :ok (admission_applications_map_student_spec.rb).
# Sem cobertura (#720): abrir o mapeamento (map_student), o formulario
# intermediario (map_student_form, que pre-preenche aluno e matricula a partir
# da inscricao) e as respostas reais de cada passo em html, xhr e iframe.
RSpec.describe "Mapeamento de candidato em aluno", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "map_flow_admin@ic.uff.br"
    )
    @level = FactoryBot.create(:level)
    @enrollment_status = FactoryBot.create(:enrollment_status)
    @process = FactoryBot.create(:admission_process, level: @level, enrollment_status: @enrollment_status)
    @application = FactoryBot.create(
      :admission_application, admission_process: @process,
      name: "Candidata Mapeada", email: "candidata_map@ic.uff.br"
    )
  end

  def xhr_headers
    { "X-Requested-With" => "XMLHttpRequest", "Accept" => "text/javascript" }
  end

  def create_update_params
    {
      record_student: { name: "Aluna Mapeada", cpf: "map-flow-cpf-1" },
      record_enrollment: {
        enrollment_number: "M-map-flow-1",
        "admission_date(1i)" => "2024", "admission_date(2i)" => "1", "admission_date(3i)" => "1",
        enrollment_status: @enrollment_status.id, level: @level.id,
      },
    }
  end

  describe "GET map_student" do
    it "abre em pagina propria a escolha do aluno, listando o aluno achado pelo e-mail" do
      FactoryBot.create(:student, name: "Aluno Do Email", email: "candidata_map@ic.uff.br")

      get map_student_admission_application_path(@application)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mapeamento de")
      expect(response.body).to include("Encontrado(a) por email: ")
      expect(response.body).to include("Aluno Do Email")
      expect(response.body).to include("Abrir formulário de mapeamento")
      expect(response.body).not_to include('data-remote="true"')
    end

    it "devolve so o formulario remoto quando aberto pelo action link" do
      get map_student_admission_application_path(@application), headers: xhr_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Abrir formulário de mapeamento")
      expect(response.body).to include('data-remote="true"')
      expect(response.body).not_to include("<html")
    end

    context "com aluno ja ligado a inscricao" do
      before(:each) do
        @aluno = FactoryBot.create(:student, name: "Aluno Ligado")
        @application.update!(student: @aluno)
      end

      it "pula a escolha e abre direto a edicao do aluno associado" do
        get map_student_admission_application_path(@application)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Editar aluno associado")
        expect(response.body).to include("Criar nova matrícula")
        expect(response.body).not_to include("Abrir formulário de mapeamento")
      end

      it "pelo action link devolve o formulario de gravacao, sem o js de troca" do
        get map_student_admission_application_path(@application), headers: xhr_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Editar aluno associado")
        expect(response.body).not_to include("ActiveScaffold.replace")
      end
    end
  end

  describe "POST map_student_form" do
    it "pre-preenche um aluno novo com o nome e o e-mail da inscricao" do
      post map_student_form_admission_application_path(@application)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar novo aluno")
      expect(response.body).to include("Criar nova matrícula")
      expect(response.body).to include('value="Candidata Mapeada"')
      expect(response.body).to include('value="candidata_map@ic.uff.br"')
      expect(Student.count).to eq(0)
    end

    it "associa o aluno existente escolhido" do
      aluno = FactoryBot.create(:student, name: "Aluno Escolhido")

      post map_student_form_admission_application_path(@application), params: { student_id: aluno.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Associar aluno existente")
      expect(response.body).to include(%(name="student_id" id="student_id" value="#{aluno.id}"))
    end

    it "pelo formulario remoto devolve o js que troca o formulario" do
      post map_student_form_admission_application_path(@application), headers: xhr_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include("ActiveScaffold.replace(")
      expect(response.body).to include("Criar novo aluno")
    end

    context "quando o edital pede um campo de matricula que o candidato nao tem" do
      before(:each) { @process.update!(enrollment_number_field: "Campo Inexistente") }

      it "volta para a lista com o erro no flash" do
        post map_student_form_admission_application_path(@application)

        expect(response).to redirect_to(admission_applications_path)
        expect(flash[:error]).to include(
          "Campo de número da matrícula definido no edital não encontrado em candidato: Campo Inexistente"
        )
      end

      # O js nao olha o successful?: troca o formulario do mesmo jeito e
      # leva o erro nas mensagens do action link.
      it "pelo formulario remoto ainda devolve o js com o formulario e o erro" do
        post map_student_form_admission_application_path(@application), headers: xhr_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("update_flash_messages(")
        expect(response.body).to include("Campo Inexistente")
        expect(response.body).to include("ActiveScaffold.replace(")
      end
    end

    # Defesa: a tela nunca manda iframe=true para este passo, mas a resposta
    # existe e tem de continuar respondendo a uma requisicao montada a mao.
    it "com iframe=true responde ao frame pai com o js do formulario" do
      post map_student_form_admission_application_path(@application), params: { iframe: "true" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("with(window.parent)")
      expect(response.body).to include("ActiveScaffold.replace(")
    end
  end

  describe "POST map_student_form_create_update" do
    it "pelo upload em iframe, caminho do formulario multipart, grava e responde ao frame pai" do
      expect do
        post map_student_form_create_update_admission_application_path(@application),
          params: create_update_params.merge(iframe: "true"), headers: { "X-Requested-With" => "XMLHttpRequest" }
      end.to change { Student.count }.by(1).and change { Enrollment.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("with(window.parent)")
      expect(response.body).to include("action_link.close(")
      expect(@application.reload.student.name).to eq("Aluna Mapeada")
    end

    it "sem js grava e volta para a lista com a mensagem de sucesso" do
      expect do
        post map_student_form_create_update_admission_application_path(@application),
          params: create_update_params
      end.to change { Student.count }.by(1)

      expect(response).to redirect_to(admission_applications_path)
      expect(flash[:info]).to include("Aluna Mapeada")
    end

    it "sem js, com aluno invalido, devolve o formulario com o digitado" do
      params = create_update_params
      params[:record_student][:cpf] = ""

      expect do
        post map_student_form_create_update_admission_application_path(@application), params:
      end.not_to change { Student.count }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar novo aluno")
      expect(response.body).to include('value="Aluna Mapeada"')
    end

    # Defesa: com o formulario sempre multipart, xhr sem iframe so chega forjado.
    it "por xhr sem iframe devolve o js que fecha o action link" do
      post map_student_form_create_update_admission_application_path(@application),
        params: create_update_params, headers: xhr_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include("action_link.close(")
      expect(@application.reload.enrollment.enrollment_number).to eq("M-map-flow-1")
    end
  end
end

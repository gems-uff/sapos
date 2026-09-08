# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O spec de modelo do Ability fixa a resposta da regra; este fixa o percurso que
# leva o argumento ate ela, e os dois nao sao a mesma coisa.
#
# A regra do papel Aluno em initialize_documents decide por matricula:
# `matricula_aluno.in?(user.student.enrollments.pluck(:enrollment_number))`. Quem
# escolhe o valor desse segundo argumento e o controller, em
# `authorize! :generate_assertion, @assertion, get_query_params[:matricula_aluno]`
# -- e `get_query_params` desembrulha `params[:query_params]`, que chega da query
# string. Nada media esse desembrulho: se ele passasse a devolver nil, `can?`
# recusaria tudo e a declaracao do proprio aluno pararia de sair, sem um unico
# exemplo caindo.
#
# A recusa aparece como 500, porque CanCan::AccessDenied nao tem mapeamento em
# rescue_responses -- e a pagina que o SAPOS mostra a quem e barrado. O mesmo
# registro esta em spec/requests/student_enrollment_spec.rb.
RSpec.describe "Assertion authorization", type: :request do
  before(:each) do
    @role_aluno = FactoryBot.create(:role_aluno)

    query = Query.new(
      name: "declaracao_de_matricula",
      sql: "select :matricula_aluno as matricula"
    )
    # student_can_generate exige que a query tenha esse parametro e so ele
    # (Assertion#only_student_enrollment_param).
    query.params.build(
      name: "matricula_aluno", value_type: "String", default_value: ""
    )
    query.save!

    @assertion = Assertion.create!(
      name: "Declaracao de matricula", query: query,
      template_type: "Liquid", assertion_template: "Matricula: {{ matricula }}",
      student_can_generate: true
    )

    @student = FactoryBot.create(:student, name: "Discente")
    @enrollment = FactoryBot.create(
      :enrollment, student: @student, enrollment_number: "M01"
    )
    sign_in create_confirmed_user(
      [@role_aluno], "aluno_declaracao@ic.uff.br", "Ana", "A1b2c3d4!",
      student: @student
    )
  end

  def get_assertion_pdf(enrollment_number)
    get assertion_pdf_assertion_path(
      @assertion,
      query_params: { matricula_aluno: enrollment_number },
      format: :pdf
    )
  end

  describe "GET assertion_pdf in the student role" do
    # Tambem e o contraponto da guarda `user.student.present?` que envolve o
    # ramo inteiro: escrita larga demais, negando :assertion_pdf a todos, este
    # exemplo acusa. O `authorize_resource` do AssertionsController confere essa
    # permissao antes de qualquer coisa carregar.
    it "generates the pdf of its own enrollment number" do
      get_assertion_pdf(@enrollment.enrollment_number)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "application/pdf"
    end

    it "refuses the enrollment number of another student" do
      other = FactoryBot.create(
        :enrollment, enrollment_number: "M02",
        student: FactoryBot.create(:student, name: "Outro")
      )

      get_assertion_pdf(other.enrollment_number)

      expect(response).to have_http_status(:internal_server_error)
      expect(response.media_type).not_to eq "application/pdf"
    end

    # A recusa nao pode vir de uma declaracao que ninguem pode gerar: sem este
    # exemplo, `student_can_generate` ignorado passaria pelos dois de cima.
    it "refuses an assertion that students are not allowed to generate" do
      closed = Assertion.create!(
        name: "Declaracao interna", query: @assertion.query,
        template_type: "Liquid", assertion_template: "Corpo",
        student_can_generate: false
      )

      get assertion_pdf_assertion_path(
        closed,
        query_params: { matricula_aluno: @enrollment.enrollment_number },
        format: :pdf
      )

      expect(response).to have_http_status(:internal_server_error)
      expect(response.media_type).not_to eq "application/pdf"
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Colunas de show que montam uma tabela HTML por concatenacao e a marcam como
# segura: todo dado de registro interpolado tem de sair escapado. Cada grupo
# confere o texto comum (controle) e o texto com marcacao.
RSpec.describe ProfessorsHelper, "colunas de show", type: :helper do
  let(:marcacao) { "<b>marcado</b>" }
  let(:escapada) { "&lt;b&gt;marcado&lt;/b&gt;" }

  before(:each) { @professor = FactoryBot.create(:professor) }

  describe "orientacoes com pontos" do
    def tabela(nome, numero)
      matricula = FactoryBot.create(:enrollment, enrollment_number: numero,
        student: FactoryBot.create(:student, name: nome))
      FactoryBot.create(:advisement_authorization, professor: @professor, level: matricula.level)
      FactoryBot.create(:advisement, professor: @professor, enrollment: matricula, main_advisor: true)
      helper.professor_advisements_with_points_show_column(@professor, nil)
    end

    it "mostra nome e matricula do aluno" do
      expect(tabela("Ana Clara", "M-10")).to include("<td>Ana Clara</td>", "<td>M-10</td>")
    end

    it "escapa nome e matricula do aluno" do
      saida = tabela(marcacao, "M#{marcacao}")

      expect(saida).not_to include(marcacao)
      expect(saida).to include("<td>#{escapada}</td>", "<td>M#{escapada}</td>")
    end
  end

  describe "vinculos com instituicao" do
    def tabela(nome)
      FactoryBot.create(:affiliation, professor: @professor,
        institution: FactoryBot.create(:institution, name: nome))
      helper.professor_institutions_show_column(@professor.reload, nil)
    end

    it "mostra o nome da instituicao" do
      expect(tabela("Universidade Exemplo")).to include("<td>Universidade Exemplo</td>")
    end

    it "escapa o nome da instituicao" do
      saida = tabela(marcacao)

      expect(saida).not_to include(marcacao)
      expect(saida).to include("<td>#{escapada}</td>")
    end
  end
end

RSpec.describe EnrollmentRequestsHelper, "colunas de show", type: :helper do
  let(:marcacao) { "<b>marcado</b>" }
  let(:escapada) { "&lt;b&gt;marcado&lt;/b&gt;" }

  before(:each) do
    @pedido = FactoryBot.create(:enrollment_request)
  end

  describe "comentarios do pedido" do
    def tabela(autor, mensagem)
      usuario = FactoryBot.create(:user, name: autor)
      FactoryBot.create(:enrollment_request_comment, enrollment_request: @pedido,
        user: usuario, message: mensagem)
      helper.enrollment_request_comments_show_column(@pedido.reload, nil)
    end

    it "mostra autor e mensagem" do
      expect(tabela("Ana Clara", "Posso trocar de turma?")).to include(
        "<td>Ana Clara</td>", "<td>Posso trocar de turma?</td>"
      )
    end

    it "escapa autor e mensagem" do
      saida = tabela(marcacao, "pedido #{marcacao}")

      expect(saida).not_to include(marcacao)
      expect(saida).to include("<td>#{escapada}</td>", "<td>pedido #{escapada}</td>")
    end
  end

  describe "disciplinas do pedido" do
    def tabela(nome)
      turma = FactoryBot.create(:course_class, name: nome,
        course: FactoryBot.create(:course, name: nome))
      FactoryBot.create(:class_enrollment_request, enrollment_request: @pedido, course_class: turma)
      helper.class_enrollment_requests_show_column(@pedido.reload, nil)
    end

    it "mostra a turma" do
      expect(tabela("Algoritmos")).to include("Algoritmos")
    end

    it "escapa a turma" do
      saida = tabela(marcacao)

      expect(saida).not_to include(marcacao)
      expect(saida).to include(escapada)
    end
  end
end

RSpec.describe ScholarshipsHelper, "alocacoes da bolsa", type: :helper do
  let(:marcacao) { "<b>marcado</b>" }
  let(:escapada) { "&lt;b&gt;marcado&lt;/b&gt;" }

  def tabela(nome)
    bolsa = FactoryBot.create(:scholarship,
      start_date: Date.new(2025, 1, 1), end_date: Date.new(2027, 12, 31))
    FactoryBot.create(:scholarship_duration, scholarship: bolsa,
      start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 1),
      enrollment: FactoryBot.create(:enrollment, enrollment_number: "M-20",
        student: FactoryBot.create(:student, name: nome)))
    helper.scholarship_durations_show_column(bolsa.reload, nil)
  end

  it "mostra matricula e nome do aluno" do
    expect(tabela("Ana Clara")).to include("<td>M-20 - Ana Clara</td>")
  end

  it "escapa o nome do aluno" do
    saida = tabela(marcacao)

    expect(saida).not_to include(marcacao)
    expect(saida).to include("<td>M-20 - #{escapada}</td>")
  end
end

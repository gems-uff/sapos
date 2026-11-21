# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O active_scaffold calcula o to_label do registro para a mensagem de sucesso
# da gravacao (o titulo da edicao destes cadastros e vazio), e nenhum exemplo
# gravava estes cadastros pela tela (#720): um to_label que levantasse
# (associacao nil, metodo renomeado) derrubaria a gravacao com 500. Cada
# exemplo grava pela tela e confere o rotulo que a mensagem recebe.
RSpec.describe "Mensagem de gravacao pelo to_label", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_to_label@ic.uff.br", "Adm"
    )
    @professor = FactoryBot.create(:professor, name: "Prof Rotulo")
    @area = FactoryBot.create(:research_area, name: "Area Rotulo", code: "AR")
    @linha = FactoryBot.create(:research_line, name: "Linha Rotulo", research_area: @area)
    @comissao = FactoryBot.create(:admission_committee, name: "Comissao Rotulo")
  end

  # A mensagem em si nao traz o rotulo: o pt-BR nao traduz o updated_model do
  # active_scaffold, que cai no texto padrao. O rotulo e conferido no registro.
  def grava(caminho, campos, registro)
    put caminho, params: { record: campos }
    expect(response).to have_http_status(:found)
    expect(flash[:info]).to be_present
    registro.reload.to_label
  end

  it "comissao de selecao" do
    expect(grava(admission_committee_path(@comissao), { name: "Comissao Renomeada" }, @comissao))
      .to eq("Comissao Renomeada")
  end

  it "membro de comissao: comissao e usuario" do
    membro = FactoryBot.create(
      :admission_committee_member, admission_committee: @comissao,
      user: create_confirmed_user([], "membro_rotulo@ic.uff.br", "Membro Rotulo")
    )

    expect(grava(admission_committee_member_path(membro), { admission_committee: @comissao.id, user: membro.user_id }, membro))
      .to eq("Comissao Rotulo - Membro Rotulo")
  end

  it "comissao de fase: fase e comissao" do
    fase = FactoryBot.create(:admission_phase, name: "Fase Rotulo")
    ligacao = FactoryBot.create(:admission_phase_committee, admission_phase: fase, admission_committee: @comissao)

    expect(grava(admission_phase_committee_path(ligacao), { admission_phase: fase.id, admission_committee: @comissao.id }, ligacao))
      .to eq("Fase Rotulo - Comissao Rotulo")
  end

  it "linha de pesquisa de disciplina: linha e area" do
    curso = FactoryBot.create(:course)
    FactoryBot.create(:course_research_area, course: curso, research_area: @area)
    ligacao = FactoryBot.create(:course_research_line, course: curso, research_line: @linha)

    expect(grava(course_research_line_path(ligacao), { course: curso.id, research_line: @linha.id }, ligacao))
      .to eq("Linha Rotulo - Area Rotulo")
  end

  it "area de pesquisa de professor: professor e area" do
    ligacao = FactoryBot.create(:professor_research_area, professor: @professor, research_area: @area)

    expect(grava(professor_research_area_path(ligacao), { professor: @professor.id, research_area: @area.id }, ligacao))
      .to eq("Prof Rotulo - Area Rotulo")
  end

  it "linha de pesquisa de professor: professor e linha" do
    FactoryBot.create(:professor_research_area, professor: @professor, research_area: @area)
    ligacao = FactoryBot.create(:professor_research_line, professor: @professor, research_line: @linha)

    expect(grava(professor_research_line_path(ligacao), { professor: @professor.id, research_line: @linha.id }, ligacao))
      .to eq("Prof Rotulo - Linha Rotulo")
  end

  it "formacao de aluno: aluno e curso" do
    formacao = FactoryBot.create(
      :student_major, student: FactoryBot.create(:student, name: "Aluno Rotulo"),
      major: FactoryBot.create(:major, name: "Curso Rotulo")
    )

    expect(grava(student_major_path(formacao), { student: formacao.student_id, major: formacao.major_id }, formacao))
      .to eq("Aluno Rotulo - Curso Rotulo")
  end
end

# Avaliacao e resultado de fase nao tem edicao nem exibicao (o controller exclui
# :update e :show); o to_label serve as listas e associacoes que os citam.
RSpec.describe "to_label de avaliacao e resultado de fase", type: :model do
  before(:each) do
    @candidatura = FactoryBot.create(:admission_application, name: "Candidata Rotulo")
  end

  it "avaliacao: fase, candidatura e avaliador" do
    avaliacao = FactoryBot.create(
      :admission_phase_evaluation, admission_application: @candidatura,
      admission_phase: FactoryBot.create(:admission_phase, :with_member_form, name: "Fase Aval"),
      user: create_confirmed_user([], "avaliador_rotulo@ic.uff.br", "Avaliador Rotulo")
    )

    expect(avaliacao.to_label).to eq("Fase Aval / #{@candidatura.to_label} / Avaliador Rotulo")
    expect(@candidatura.to_label).to start_with("Candidata Rotulo - ")
  end

  it "resultado: fase, candidatura e modo" do
    resultado = FactoryBot.create(
      :admission_phase_result, admission_application: @candidatura,
      admission_phase: FactoryBot.create(:admission_phase, :with_shared_form, name: "Fase Res")
    )

    expect(resultado.to_label)
      .to eq("Fase Res / #{@candidatura.to_label} / #{Admissions::AdmissionPhaseResult::SHARED}")
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Professor que lanca notas (professor_login_can_post_grades) abre a propria
# turma e a inscricao dela com os campos de cadastro travados (#720). Nenhum
# exemplo montava esse papel, entao o ramo `can?(:post_grades) &&
# cannot?(:update_all_fields)` dos helpers de CourseClasses e de
# ClassEnrollments nunca rodava. Cada tela vem com o controle do
# administrador, que ve os mesmos campos destravados.
RSpec.describe "Formularios do professor que lanca notas", type: :request do
  before(:each) do
    FactoryBot.create(
      :custom_variable, variable: "professor_login_can_post_grades", value: "yes_all_semesters"
    )
    @professor = FactoryBot.create(:professor, name: "Professor Notas")
    @turma = FactoryBot.create(:course_class, professors: [@professor], name: "Turma Notas")
    @inscricao = FactoryBot.create(:class_enrollment, course_class: @turma)
  end

  def entra_como_professor
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_professor)], "prof_notas@ic.uff.br", "Prof", professor: @professor
    )
  end

  def entra_como_administrador
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_notas@ic.uff.br", "Adm"
    )
  end

  def html
    Nokogiri::HTML(response.body)
  end

  # Campos de cadastro da turma, pelo nome do input.
  def campos_da_turma
    {
      "record[name]" => "input",
      "record[course]" => "input.recordselect",
      "record[year]" => "select",
      "record[semester]" => "select",
      "record[not_schedulable]" => "input[type='checkbox']",
      "record[obs_schedule]" => "input",
    }
  end

  def campo(seletor, nome)
    html.css("#{seletor}[name='#{nome}']").first
  end

  describe "edicao da turma" do
    it "o professor ve os campos de cadastro desabilitados" do
      entra_como_professor

      get edit_course_class_path(@turma)

      expect(response).to have_http_status(:ok)
      campos_da_turma.each do |nome, seletor|
        expect(campo(seletor, nome)).to be_present, nome
        expect(campo(seletor, nome)["disabled"]).to eq("disabled"), nome
      end
      expect(html.css("dl").map(&:text).join).to include("Professor Notas")
    end

    it "o administrador ve os mesmos campos habilitados" do
      entra_como_administrador

      get edit_course_class_path(@turma)

      expect(response).to have_http_status(:ok)
      campos_da_turma.each do |nome, seletor|
        expect(campo(seletor, nome)["disabled"]).to be_nil, nome
      end
      expect(campo("input.recordselect", "record[professors][]")["disabled"]).to be_nil
    end
  end

  describe "edicao da inscricao" do
    # O campo de nota que nao conta no CR fica escondido para o professor.
    def item_nao_conta_no_cr
      html.css("input[type='checkbox'][name='record[grade_not_count_in_gpr]']").first
        .ancestors("dl").first
    end

    it "o professor ve aluno e turma travados e o campo de CR escondido" do
      entra_como_professor

      get edit_class_enrollment_path(@inscricao)

      expect(response).to have_http_status(:ok)
      expect(campo("input.recordselect", "record[enrollment]")["disabled"]).to eq("disabled")
      expect(campo("input.recordselect", "record[course_class]")["disabled"]).to eq("disabled")
      expect(item_nao_conta_no_cr["style"]).to eq("display:none;")
    end

    it "o administrador ve aluno, turma e campo de CR liberados" do
      entra_como_administrador

      get edit_class_enrollment_path(@inscricao)

      expect(response).to have_http_status(:ok)
      expect(campo("input.recordselect", "record[enrollment]")["disabled"]).to be_nil
      expect(campo("input.recordselect", "record[course_class]")["disabled"]).to be_nil
      expect(item_nao_conta_no_cr["style"].to_s).not_to include("display:none")
    end
  end
end

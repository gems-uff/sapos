# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Admissions::AdmissionApplication#students_by_cpf e o que oferece a secretaria
# a ficha que a pessoa ja tem, na hora de transformar o candidato em aluno. O
# candidato digita o CPF em campo de texto livre, quase sempre so os digitos, e
# a ficha antiga costuma estar pontuada. Os exemplos verdes fixam os formatos
# que a busca ja atravessa; o pending reproduz o que ela ainda perde, e fica
# assim ate a issue #674 definir a forma unica de gravar o CPF.
RSpec.describe Admissions::AdmissionApplication, type: :model do
  describe "#students_by_cpf entre formatos de CPF" do
    before(:each) do
      @template = create_admission_template("Inscrição com CPF", {
        "cpf" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "cpf" } },
      })
      @process = create_closed_admission_process(@template, simple_url: "cpf-formato-spec")
    end

    def candidatura(cpf)
      create_application(@process, fields: { "cpf" => cpf })
    end

    it "acha a ficha gravada só com dígitos quando o candidato digita com pontuação" do
      ficha = FactoryBot.create(:student, cpf: "52998224725")
      expect(candidatura("529.982.247-25").students_by_cpf).to contain_exactly(ficha)
    end

    it "acha a ficha quando o candidato deixa espaço antes e depois do CPF" do
      ficha = FactoryBot.create(:student, cpf: "529.982.247-25")
      expect(candidatura(" 52998224725 ").students_by_cpf).to contain_exactly(ficha)
    end

    it "não confunde CPF diferentes" do
      FactoryBot.create(:student, cpf: "529.982.247-25")
      expect(candidatura("11144477735").students_by_cpf).to be_empty
    end

    it "acha a ficha quando o candidato separa os blocos com espaço", pending: "issue #674" do
      ficha = FactoryBot.create(:student, cpf: "529.982.247-25")
      expect(candidatura("529 982 247 25").students_by_cpf).to contain_exactly(ficha)
    end
  end

  # A cópia da candidatura para a ficha (update_student) leva o CPF como o
  # candidato o digitou. Pela regra de preenchimento da issue #674, a ficha
  # guarda o CPF pontuado, e a conversão é da ficha, não da candidatura.
  describe "#update_student e a forma gravada do CPF" do
    before(:each) do
      @template = create_admission_template("Inscrição com nome e CPF", {
        "nome" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_NAME },
        "cpf" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "cpf" } },
      })
      @process = create_closed_admission_process(@template, simple_url: "cpf-copia-spec")
    end

    def ficha_copiada(cpf)
      application = create_application(@process, name: "Ana", fields: { "nome" => "Ana Maria", "cpf" => cpf })
      student = Student.new
      application.reload.update_student(student)
      student.save!
      student.reload
    end

    it "grava pontuado o CPF que o candidato digitou pontuado" do
      expect(ficha_copiada("529.982.247-25").cpf).to eq("529.982.247-25")
    end

    it "grava pontuado o CPF que o candidato digitou só com os dígitos", pending: "issue #674" do
      expect(ficha_copiada("52998224725").cpf).to eq("529.982.247-25")
    end
  end
end

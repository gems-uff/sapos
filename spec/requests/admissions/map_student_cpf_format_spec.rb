# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A tela que transforma o candidato em aluno grava o CPF como o candidato o
# digitou. Quando a pessoa ja tem ficha com o CPF pontuado e o candidato digita
# so os digitos, a unicidade nao reconhece o CPF e nasce a segunda ficha da
# mesma pessoa. A reproducao fica pending ate a issue #674 definir a forma
# unica de gravar o CPF; o controle, sem pending, prova que o cenario monta e
# que a tela ja recusa o CPF repetido quando ele vem escrito do mesmo jeito.
RSpec.describe "Admissions::AdmissionApplications map_student e o formato do CPF",
  type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "map_student_cpf@ic.uff.br")
    sign_in @admin

    @admission_application = FactoryBot.create(:admission_application)
    @level = FactoryBot.create(:level)
    @enrollment_status = FactoryBot.create(:enrollment_status)
    @ficha = FactoryBot.create(:student, name: "Aluna Antiga", cpf: "529.982.247-25")

    # A resposta reconstroi o formulario inteiro do ActiveScaffold; o que se
    # mede aqui acontece antes dela, em do_map_student_form_create_update.
    allow_any_instance_of(Admissions::AdmissionApplicationsController)
      .to receive(:respond_to_action) { |controller, *| controller.head :ok }
  end

  def do_map_student(cpf)
    post map_student_form_create_update_admission_application_path(
      @admission_application
    ), params: {
      record_student: { name: "Aluna Antiga", cpf: cpf },
      record_enrollment: {
        enrollment_number: "M-map-cpf-1",
        "admission_date(1i)" => "2024",
        "admission_date(2i)" => "1",
        "admission_date(3i)" => "1",
        enrollment_status: @enrollment_status.id,
        level: @level.id,
      },
    }
  end

  it "não cria a segunda ficha quando o CPF vem escrito como o da ficha existente" do
    expect { do_map_student("529.982.247-25") }
      .not_to change { [Student.count, Enrollment.count] }
  end

  it "não cria a segunda ficha quando o CPF vem só com os dígitos", pending: "issue #674" do
    expect { do_map_student("52998224725") }
      .not_to change { [Student.count, Enrollment.count] }
  end

  # A forma gravada: o CPF de quem ainda não tem ficha fica pontuado, venha
  # como vier. O controle fixa o que já vale para o CPF que chega pontuado.
  it "cria a ficha com o CPF pontuado quando ele chega pontuado" do
    expect { do_map_student("111.444.777-35") }.to change { Student.count }.by(1)
    expect(Student.order(:id).last.cpf).to eq("111.444.777-35")
  end

  it "cria a ficha com o CPF pontuado quando ele chega só com os dígitos", pending: "issue #674" do
    expect { do_map_student("11144477735") }.to change { Student.count }.by(1)
    expect(Student.order(:id).last.cpf).to eq("111.444.777-35")
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Estes falham. O PR esconde o campo de nota quando a disciplina nao tem nota
# -- no formulario da inscricao (hide_form_column_if) e no subform da turma
# (subform_column_omitted?). Mas uma inscricao pode ter nota gravada de antes
# de o tipo da disciplina passar a "sem nota", e as duas telas deixam fazer
# essa troca. Sem o campo, a nota nunca e reenviada nem pode ser limpa, e
# grade_filled_for_course_without_score recusa qualquer edicao daquele
# registro -- ate de obs, ou do nome da turma -- com erro sobre um campo que
# nao esta na tela. Na main o campo aparece com a nota, e limpa-lo resolve.
#
# Os exemplos afirmam a saida que a main oferecia: o campo continua no
# formulario enquanto houver nota a limpar. Se o conserto escolhido for outro
# -- limpar a nota ao esconder o campo, por exemplo --, troque-os por um que
# salve o registro pela tela.
#
# Controle: com o class_enrollments_controller e as copias de partial da main,
# passam.
RSpec.describe "Nota gravada em disciplina que deixou de ter nota", type: :request do
  let(:course_type) { FactoryBot.create(:course_type, has_score: true) }
  let(:course) { FactoryBot.create(:course, course_type: course_type) }
  let(:turma) { FactoryBot.create(:course_class, course: course) }
  let!(:inscricao) do
    FactoryBot.create(
      :class_enrollment, course_class: turma,
      grade: 80, situation: ClassEnrollment::APPROVED
    )
  end

  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "admin@ic.uff.br")
    course_type.update!(has_score: false)
  end

  def campos_de_nota(seletor)
    Nokogiri::HTML(response.body).css(seletor).reject { |campo| campo["type"] == "hidden" }
  end

  context "defeitos em aberto" do
    it "oferece no formulario da inscricao o campo para limpar a nota" do
      get edit_class_enrollment_path(inscricao)

      expect(campos_de_nota("input[name='record[grade]']")).not_to be_empty
    end

    it "oferece no subform da turma o campo para limpar a nota" do
      get edit_course_class_path(turma)

      expect(
        campos_de_nota("input[name='record[class_enrollments][#{inscricao.id}][grade]']")
      ).not_to be_empty
    end
  end
end

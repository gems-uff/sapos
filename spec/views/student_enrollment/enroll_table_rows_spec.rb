# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Linhas do quadro da inscricao online: cada celula de dia traz texto montado
# do horario (dia, hora, sala, professor), com "\n" entre as partes, que vira
# <br>. O texto tem de sair escapado.
RSpec.describe "student_enrollment/linhas do quadro de inscricao", type: :view do
  before(:each) do
    view.extend StudentEnrollmentHelper
    @pedido = EnrollmentRequest.new
  end

  def linha(celula)
    form = ActionView::Helpers::FormBuilder.new(:enrollment_request, nil, view, {})
    {
      form: form, semester: nil, enrollment_request: @pedido, closed: true, cer: nil,
      row_index: 0, count: 1, select_professor: nil,
      table: { header: [["", "Disciplina", "Segunda", "Professor"]] },
      row: [{ id: 1, course_id: 1, on_demand: false, professors: [] }, "Algoritmos", celula, "Prof"]
    }
  end

  %w[enroll_table_default_row enroll_table_on_demand_row].each do |parcial|
    describe parcial do
      it "quebra a linha da celula em <br>" do
        render partial: "student_enrollment/#{parcial}", locals: linha("10:00-12:00\nSala 1")

        expect(rendered).to match(%r{10:00-12:00\s*<br\s*/?>\s*Sala 1})
      end

      it "escapa o texto da celula" do
        render partial: "student_enrollment/#{parcial}", locals: linha("10:00-12:00\nSala <b>marcado</b>")

        expect(rendered).not_to include("<b>marcado</b>")
        expect(rendered).to include("Sala &lt;b&gt;marcado&lt;/b&gt;")
      end
    end
  end
end

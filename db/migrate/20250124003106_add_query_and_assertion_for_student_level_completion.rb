# frozen_string_literal: true

class AddQueryAndAssertionForStudentLevelCompletion < ActiveRecord::Migration[7.0]
  def up
    query = {
      name: "DECLARAÇÃO - Conclusão de curso",
      description: "Declaração de conclusão de curso.",
      params: [
        {
          name: "matricula_aluno",
          value_type: "String",
        }
      ],
      sql: <<~SQL
        SELECT
            s.name as nome_aluno,
            s.cpf as cpf_aluno,
            e.enrollment_number as matricula_aluno,
            l.name as nivel_aluno,
            e.thesis_title as titulo_tese,
            e.thesis_defense_date as data_defesa_tese
        FROM
            enrollments e, students s, levels l, dismissals d, dismissal_reasons dr
        WHERE
            e.student_id = s.id AND
            e.level_id = l.id AND
            d.enrollment_id = e.id AND
            d.dismissal_reason_id = dr.id AND
            dr.thesis_judgement = 'Aprovado' AND
            e.enrollment_number = :matricula_aluno;
      SQL
    }

    query_obj = Query.new(query.except(:params))
    query[:params].map do |query_param|
      query_obj.params.build(query_param)
    end
    query_obj.save!

    Assertion.reset_column_information
    assertion = {
      name: "Declaração de conclusão de curso",
      student_can_generate: true,
      query_id: query_obj.id,
      assertion_template: "Declaramos, para os devidos fins, que <%= var('nome_aluno') %>, CPF: <%= var('cpf_aluno') %>, matrícula <%= var('matricula_aluno') %>, cumpriu todos os requisitos para obtenção do título de <%= var('nivel_aluno') == 'Doutorado' ? 'Doutor' : 'Mestre' %>, tendo defendido, com aprovação, a Dissertação intitulada \"<%= var('titulo_tese') %>\", em <%= localize(var('data_defesa_tese'), :longdate) %>.",
    }
    assertion_obj = Assertion.new(assertion)
    assertion_obj.save!
  end

  def down
    assertion = Assertion.find_by(name: "Declaração de conclusão de curso")
    assertion.destroy if assertion

    query = Query.find_by(name: "DECLARAÇÃO - Conclusão de curso")
    query_param = QueryParam.where(query_id: query.id)
    query_param.destroy_all if query_param

    query.destroy if query
  end
end

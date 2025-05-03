class AddQueryAndAssertionForAvulsoStudent < ActiveRecord::Migration[7.0]
  def up
    query = {
      name: "DECLARAÇÃO - Disciplinas de aluno avulso",
      description: "Recupera as notas das disciplinas que um avulso obteve num determinado ano/semestre.",
      params: [
        {
          name: "matricula_aluno",
          value_type: "String",
        },
        {
          name: "ano_semestre_busca",
          value_type: "Integer",
        },
        {
          name: "numero_semestre_busca",
          value_type: "Integer",
        },
      ],
      sql: <<~SQL
        SELECT
          s.name as nome_aluno,
          c.name as nome_disciplina,
          c.workload as carga_horaria,
          cs.year as ano_disciplina,
          cs.semester as semestre_disciplina,
          ce.grade as nota,
          ce.situation as situacao
        FROM
          course_classes cs, class_enrollments ce, enrollments e, courses c, students s
        WHERE
          cs.id = ce.course_class_id AND
          ce.enrollment_id = e.id AND
          c.id = cs.course_id AND
          e.student_id = s.id AND
          cs.year = :ano_semestre_busca AND
          cs.semester = :numero_semestre_busca AND
          e.enrollment_number = :matricula_aluno
      SQL
    }

    query_obj = Query.new(query.except(:params))
    query[:params].map do |query_param|
      query_obj.params.build(query_param)
    end
    query_obj.save!

    Assertion.reset_column_information
    assertion = {
      name: "Declaração de relatório de disciplinas para aluno avulso",
      query_id: query_obj.id,
      assertion_template: "
        Declaro, para os devidos fins, que <%= var('nome_aluno') %> cursou como Aluno Avulso as seguintes disciplinas do Programa de Pós-Graduação em Computação, nos termos do Art. 15 do Regulamento dos Programas de Pós-Graduação Stricto Sensu da Universidade Federal Fluminense.

        <% records.each do |record| %>
          Nome da disciplina: <%= record['nome_disciplina'] %>
          Carga horaria total: <%= record['carga_horaria'] %>
          Período: <%= var('ano_disciplina') %>/<%= var('semestre_disciplina') %>
          Nota: <%= record['nota'] %>
          Situação final: <%= record['situacao'] %>

        <% end %>"
    }

    assertion_obj = Assertion.new(assertion)
    assertion_obj.save!(validate: false)
  end

  def down
    assertion = Assertion.find_by(name: "Declaração de relatório de disciplinas para aluno avulso")
    assertion.destroy if assertion

    query_param = QueryParam.where(query_id: Query.find_by(name: "DECLARAÇÃO - Disciplinas de aluno avulso").id)
    query_param.destroy_all if query_param

    query = Query.find_by(name: "DECLARAÇÃO - Disciplinas de aluno avulso")
    query.destroy if query
  end
end
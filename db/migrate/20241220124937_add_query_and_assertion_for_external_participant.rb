class AddQueryAndAssertionForExternalParticipant < ActiveRecord::Migration[7.0]
  def up
    query = {
      name: "DECLARAÇÃO - Participante externo em defesa de tese",
      description: "Declaração de participante externo em defesa de dissertação.",
      params: [
        {
          name: "matricula_aluno",
          value_type: "String",
        },
        {
          name: "cpf_professor",
          value_type: "String",
        },
      ],
      sql: <<~SQL
        SELECT
          s.name as nome_aluno,
          l.name as nivel_aluno,
          e.thesis_defense_date as data,
          p.name as nome_professor
        FROM
          thesis_defense_committee_participations tdcp, enrollments e, students s, professors p, levels l
        WHERE
          tdcp.enrollment_id = e.id AND
          e.student_id = s.id AND
          tdcp.professor_id = p.id AND
          e.level_id = l.id AND
          e.enrollment_number = :matricula_aluno AND
          p.cpf = :cpf_professor
      SQL
    }

    query_obj = Query.new(query.except(:params))
    query[:params].map do |query_param|
      query_obj.params.build(query_param)
    end
    query_obj.save!

    assertion = {
      name: "Declaração de participante externo em defesa de tese",
      query_id: query_obj.id,
      assertion_template: "A quem possa interessar, declaramos que o professor(a) <%= var('nome_professor') %> participou da banca de defesa da dissertação de <%= var('nivel_aluno') %> de <%= var('nome_aluno') %>, no dia <%= localize(var('data'), :longdate) %>.",
    }
    assertion_obj = Assertion.new(assertion)
    assertion_obj.save!
  end

  def down
    assertion = Assertion.find_by(name: "Declaração de participante externo em defesa de tese")
    assertion.destroy if assertion

    query_param = QueryParam.where(query_id: Query.find_by(name: "DECLARAÇÃO - Participante externo em defesa de tese").id)
    query_param.destroy_all if query_param

    query = Query.find_by(name: "DECLARAÇÃO - Participante externo em defesa de tese")
    query.destroy if query
  end
end
class AddQueryAndAssertionForExternalParticipant < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      INSERT INTO queries (name, sql, description, created_at, updated_at)
      VALUES (
        'DECLARAÇÃO - Participante externo em defesa de tese',
        'SELECT
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
          p.cpf = :cpf_professor',
        'Declaração de participante externo em defesa de dissertação.',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    SQL

    query_id = execute("SELECT last_insert_rowid()").first['last_insert_rowid()']

    execute <<-SQL
      INSERT INTO query_params (query_id, name, default_value, value_type, created_at, updated_at)
      VALUES
        (#{query_id}, 'matricula_aluno', NULL, 'String', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        (#{query_id}, 'cpf_professor', NULL, 'String', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    SQL

    execute <<-SQL
      INSERT INTO assertions (name, query_id, assertion_template, created_at, updated_at)
      VALUES (
        'Declaração de participante externo em defesa de tese',
        #{query_id},
        'A quem possa interessar, Declaramos que o professor <%= var(''nome_professor'') %> participou da banca de defesa da dissertação de <%= var(''nivel_aluno'') %> de <%= var(''nome_aluno'') %>, no dia <%= var(''data'') %>.',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    SQL
  end

  def down
    execute <<-SQL
      DELETE FROM assertions
      WHERE name = 'Declaração de participante externo em defesa de tese';
    SQL

    execute <<-SQL
      DELETE FROM query_params
      WHERE query_id = (SELECT id FROM queries WHERE name = 'DECLARAÇÃO - Participante externo em defesa de tese');
    SQL

    execute <<-SQL
      DELETE FROM queries
      WHERE name = 'DECLARAÇÃO - Participante externo em defesa de tese';
    SQL
  end
end
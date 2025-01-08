class AddQueryAndAssertionForAvulsoStudent < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      INSERT INTO queries (name, sql, description, created_at, updated_at)
      VALUES (
        'DECLARAÇÃO - Disciplinas de aluno avulso',
        'SELECT
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
          e.enrollment_number = :matricula_aluno',
        'Recupera as notas das disciplinas que um avulso obteve num determinado ano/semestre.',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    SQL

    query_id = execute("SELECT last_insert_rowid()").first['last_insert_rowid()']

    execute <<-SQL
      INSERT INTO query_params (query_id, name, default_value, value_type, created_at, updated_at)
      VALUES
        (#{query_id}, 'matricula_aluno', NULL, 'String', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        (#{query_id}, 'ano_semestre_busca', NULL, 'Integer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        (#{query_id}, 'numero_semestre_busca', NULL, 'Integer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    SQL

    execute <<-SQL
      INSERT INTO assertions (name, query_id, assertion_template, created_at, updated_at)
      VALUES (
        'Declaração de relatório de disciplinas para aluno avulso',
        #{query_id},
        'DECLARAÇÃO

        Declaro, para os devidos fins, que <%= var(''nome_aluno'') %> cursou como Aluno Avulso as seguintes disciplinas do Programa de Pós-Graduação em Computação, nos termos do Art. 15 do Regulamento dos Programas de Pós-Graduação Stricto Sensu da Universidade Federal Fluminense.

        <% records.each do |record| %>
          Nome da disciplina: "<%= record[''nome_disciplina''] %>"
          Carga horaria total: <%= record[''carga_horaria''] %>
          Período: <%= var(''ano_disciplina'') %>/<%= var(''semestre_disciplina'') %>
          Nota: <%= record[''nota''] %>
          Situação final: <%= record[''situacao''] %>

        <% end %>',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    SQL
  end

  def down
    execute <<-SQL
      DELETE FROM assertions
      WHERE name = 'Declaração de relatório de disciplinas para aluno avulso';
    SQL

    execute <<-SQL
      DELETE FROM query_params
      WHERE query_id = (SELECT id FROM queries WHERE name = 'DECLARAÇÃO - Disciplinas de aluno avulso');
    SQL

    execute <<-SQL
      DELETE FROM queries
      WHERE name = 'DECLARAÇÃO - Disciplinas de aluno avulso';
    SQL
  end
end
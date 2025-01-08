class AddQueryAndAssertionForExaminingBoard < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      INSERT INTO queries (name, sql, description, created_at, updated_at)
      VALUES (
        'DECLARAÇÃO - Banca examinadora de defesa',
        'SELECT
          s.name as nome_aluno,
          l.name as nivel_aluno,
          e.thesis_title as titulo_tese,
          e.thesis_defense_date as data,
          p.name as nome_professor,
          i.code as codigo_instituicao
        FROM
          thesis_defense_committee_participations tdcp, enrollments e, students s, professors p, levels l, institutions i
        WHERE
          tdcp.enrollment_id = e.id AND
          e.student_id = s.id AND
          tdcp.professor_id = p.id AND
          e.level_id = l.id AND
          i.id = p.institution_id AND
          e.enrollment_number = :matricula_aluno',
        'Recupera informações necessárias para a declaração de banca examinadora de defesa de um determinado aluno',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    SQL

    query_id = execute("SELECT last_insert_rowid()").first['last_insert_rowid()']

    execute <<-SQL
      INSERT INTO query_params (query_id, name, default_value, value_type, created_at, updated_at)
      VALUES
        (#{query_id}, 'matricula_aluno', NULL, 'String', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    SQL

    execute <<-SQL
      INSERT INTO assertions (name, query_id, assertion_template, created_at, updated_at)
      VALUES (
        'Declaração da ata de defesa',
        #{query_id},
        'Declaro, para os devidos fins, que a Banca Examinadora da Defesa de Dissertação de Mestrado intitulada “<%= var(''titulo_tese'') %>”, apresentada pelo aluno <%= var(''nome_aluno'') %>, no dia <%= localize(var(''data''), :longdate) %>, no $REPLACE_UNIVERSITY, foi composta pelos seguintes membros:

        <% records.each do |record| %> 
          - Prof. <%= record[''nome_professor''] %>, <%= record[''codigo_instituicao''] %>
        <% end %>',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    SQL
  end

  def down
    execute <<-SQL
      DELETE FROM assertions
      WHERE name = 'Declaração da ata de defesa';
    SQL

    execute <<-SQL
      DELETE FROM query_params
      WHERE query_id = (SELECT id FROM queries WHERE name = 'DECLARAÇÃO - Banca examinadora de defesa');
    SQL

    execute <<-SQL
      DELETE FROM queries
      WHERE name = 'DECLARAÇÃO - Banca examinadora de defesa';
    SQL
  end
end
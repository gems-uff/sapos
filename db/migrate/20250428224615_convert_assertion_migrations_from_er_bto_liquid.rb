class ConvertAssertionMigrationsFromErBtoLiquid < ActiveRecord::Migration[7.0]
  BEFORE1 = "Declaramos, para os devidos fins, que <%= var('nome_aluno') %>, CPF: <%= var('cpf_aluno') %>, matrícula <%= var('matricula_aluno') %>, cumpriu todos os requisitos para obtenção do título de <%= var('nivel_aluno') == 'Doutorado' ? 'Doutor' : 'Mestre' %>, tendo defendido, com aprovação, a Dissertação intitulada \"<%= var('titulo_tese') %>\", em <%= localize(var('data_defesa_tese'), :longdate) %>."
  AFTER1 = "Declaramos, para os devidos fins, que {{ nome_aluno }}, CPF: {{ cpf_aluno }}, matrícula {{ matricula_aluno }}, cumpriu todos os requisitos para obtenção do título de {% if nivel_aluno == 'Doutorado' %}Doutor{% else %}Mestre{% endif %}, tendo defendido, com aprovação, a Dissertação intitulada \"{{ titulo_tese }}\", em {{ data_defesa_tese | localize: 'longdate' }}."
  BEFORE2 = "
        Declaro, para os devidos fins, que <%= var('nome_aluno') %> cursou como Aluno Avulso as seguintes disciplinas do Programa de Pós-Graduação em Computação, nos termos do Art. 15 do Regulamento dos Programas de Pós-Graduação Stricto Sensu da Universidade Federal Fluminense.

        <% records.each do |record| %>
          Nome da disciplina: <%= record['nome_disciplina'] %>
          Carga horaria total: <%= record['carga_horaria'] %>
          Período: <%= var('ano_disciplina') %>/<%= var('semestre_disciplina') %>
          Nota: <%= record['nota'] %>
          Situação final: <%= record['situacao'] %>

        <% end %>"
  AFTER2 = "
        Declaro, para os devidos fins, que {{ nome_aluno }} cursou como Aluno Avulso as seguintes disciplinas do Programa de Pós-Graduação em Computação, nos termos do Art. 15 do Regulamento dos Programas de Pós-Graduação Stricto Sensu da Universidade Federal Fluminense.

        {% for record in records %}
          Nome da disciplina: {{ record.nome_disciplina }}
          Carga horaria total: {{ record.carga_horaria }}
          Período: {{ record.ano_disciplina }}/{{ record.semestre_disciplina }}
          Nota: {{ record.nota | divided_by: 10.0 }}
          Situação final: {{ record.situacao }}

        {% endfor %}"
  BEFORE3 = "A quem possa interessar, declaramos que <%= var('nome_professor') %> participou da banca de defesa da dissertação de <%= var('nivel_aluno') %> de <%= var('nome_aluno') %>, no dia <%= localize(var('data'), :longdate) %>."
  AFTER3 = "A quem possa interessar, declaramos que {{ nome_professor }} participou da banca de defesa da dissertação de {{ nivel_aluno }} de {{ nome_aluno }}, no dia {{ data | localize: 'longdate' }}."
  

  def up
    Assertion.where(assertion_template: BEFORE1).update!(assertion_template: AFTER1, template_type: "Liquid")
    Assertion.where(assertion_template: BEFORE2).update!(assertion_template: AFTER2, template_type: "Liquid")
    Assertion.where(assertion_template: BEFORE3).update!(assertion_template: AFTER3, template_type: "Liquid")
  end

  def down
    Assertion.where(assertion_template: AFTER1).update!(assertion_template: BEFORE1, template_type: "ERB")
    Assertion.where(assertion_template: AFTER2).update!(assertion_template: BEFORE2, template_type: "ERB")
    Assertion.where(assertion_template: AFTER3).update!(assertion_template: BEFORE3, template_type: "ERB")
  end  
end

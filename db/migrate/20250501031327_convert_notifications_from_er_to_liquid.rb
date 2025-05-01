class ConvertNotificationsFromErToLiquid < ActiveRecord::Migration[7.0]
  TRANSFORMATIONS = [
    { name: "SEC: Etapas vencidas [Agendamento sugerido: Mensal 4d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 3).map(&:email).join(';') %>",
        body_template: <<~ERB
          Secretaria,

          Informamos que os seguintes alunos estão com etapas vencidas:

          <% records.each do |record| %>
              - <%= record['name'] %> (etapa: <%= record['phase_name'] %>; prazo: <%= localize(record['due_date'],:defaultdate) %>)
          <% end %>

          Caso algum desses alunos tenha banca de defesa ou prorrogação aprovada pelo colegiado, por favor, cadastre no Sapos o quanto antes.
          Caso algum desses alunos tenha pedido banca de EQ, cadastre "PEQ" na observação da matrícula do aluno.
          Dentro de 5 dias o Sapos irá enviar lembrete a todos os alunos e seus orientadores.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        body_template: <<~LIQUID
          Secretaria,

          Informamos que os seguintes alunos estão com etapas vencidas:

          {% for record in records %}
              - {{ record.name }} (etapa: {{ record.phase_name }}; prazo: {{ record.due_date | localize: 'defaultdate' }})
          {% endfor %}

          Caso algum desses alunos tenha banca de defesa ou prorrogação aprovada pelo colegiado, por favor, cadastre no Sapos o quanto antes.
          Caso algum desses alunos tenha pedido banca de EQ, cadastre "PEQ" na observação da matrícula do aluno.
          Dentro de 5 dias o Sapos irá enviar lembrete a todos os alunos e seus orientadores.
        LIQUID
      },
    },
    { name: "ALUNOS: Etapas vencidas no mês seguinte [Agendamento sugerido: Mensal 9d]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        subject_template: "Prazo para realização de <%= var('phase_name') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Lembramos que vence/venceu em <%= localize(var('due_date'), :longdate) %> o prazo para <%= var('phase_name') %>.

          Para dar entrada de qualquer pedido na secretaria referente a banca ou prorrogação, é preciso observar a data limite (sexta-feira que antecede a última quarta-feira do mês de <%= localize(var('due_date'), :monthyear) %>). Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado os procedimentos para o cumprimento dessa etapa, favor desconsiderar essa mensagem.

          ------

          Lembramos que para pedido de banca de dissertação, tese ou exame de qualificação, há exigências de publicações, conforme detalhes abaixo. Para comprovar o cumprimento de alguma dessas exigências, enviar por email para a secretaria o artigo aceito ou submetido e o respectivo comprovante a qualquer momento (não é necessário esperar o pedido de banca).

          Em cada um desses casos, a comprovação do cumprimento da exigência correspondente deverá ser apresentada no máximo até a data do pedido de banca. A banca não será aprovada e a defesa não será permitida sem a devida comprovação do cumprimento da respectiva exigência. Caso mais de um discente seja coautor do mesmo artigo, esse artigo só poderá ser utilizado para efeito de cumprimento da exigência para um único aluno.

          No caso de alunos de Doutorado que tenham concluído o Mestrado anteriormente em nosso programa, o artigo usado para cumprir a exigência de publicação do Mestrado não poderá ser aproveitado para cumprir exigências do Doutorado.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Prazo para realização de {{ phase_name }}",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que vence/venceu em {{ due_date | localize: 'longdate' }} o prazo para {{ phase_name }}.

          Para dar entrada de qualquer pedido na secretaria referente a banca ou prorrogação, é preciso observar a data limite (sexta-feira que antecede a última quarta-feira do mês de {{ due_date | localize: 'monthyear' }}). Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado os procedimentos para o cumprimento dessa etapa, favor desconsiderar essa mensagem.

          ------

          Lembramos que para pedido de banca de dissertação, tese ou exame de qualificação, há exigências de publicações, conforme detalhes abaixo. Para comprovar o cumprimento de alguma dessas exigências, enviar por email para a secretaria o artigo aceito ou submetido e o respectivo comprovante a qualquer momento (não é necessário esperar o pedido de banca).

          Em cada um desses casos, a comprovação do cumprimento da exigência correspondente deverá ser apresentada no máximo até a data do pedido de banca. A banca não será aprovada e a defesa não será permitida sem a devida comprovação do cumprimento da respectiva exigência. Caso mais de um discente seja coautor do mesmo artigo, esse artigo só poderá ser utilizado para efeito de cumprimento da exigência para um único aluno.

          No caso de alunos de Doutorado que tenham concluído o Mestrado anteriormente em nosso programa, o artigo usado para cumprir a exigência de publicação do Mestrado não poderá ser aproveitado para cumprir exigências do Doutorado.
        LIQUID
      }
    },
    { name: "PROFS: Etapas vencidas no mês seguinte [Agendamento sugerido: Mensal 9d]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('prof_email') %>",
        subject_template: "Prazo para realização de <%= var('phase_name') %> de seu orientando <%= var('name') %>",
        body_template: <<~ERB
          <%= var('prof_name') %>

          Lembramos que vence/venceu em <%= localize(var('due_date'), :longdate) %> o prazo para <%= var('phase_name') %> de seu orientando <%= var('name') %>.

          Para dar entrada de qualquer pedido na secretaria referente a banca ou prorrogação, é preciso observar a data limite (sexta-feira que antecede a última quarta-feira do mês de <%= localize(var('due_date'), :monthyear) %>). Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso seu aluno já tenha realizado os procedimentos para o cumprimento dessa etapa, favor desconsiderar essa mensagem.

          ------

          Lembramos que para pedido de banca de dissertação, tese ou exame de qualificação, há exigências de publicações, conforme detalhes abaixo. Para comprovar o cumprimento de alguma dessas exigências, o aluno deve enviar por email para a secretaria o artigo aceito ou submetido e o respectivo comprovante a qualquer momento (não é necessário esperar o pedido de banca).

          ------

          [MESTRADO] [Submissão de artigo B4 ou superior] Será exigida de cada aluno de Mestrado a submissão de um artigo completo para veículo classificado no Qualis da Computação em estrato superior ou igual a B4.

          [DOUTORADO] [Submissão de artigo B4 ou superior (p/ defesa de EQ] Será exigida de cada aluno de Doutorado a submissão de um artigo completo para um veículo classificado no Qualis da Computação em estrato superior ou igual a B4, como requisito prévio necessário para a realização do exame de qualificação.

          [DOUTORADO] [Submissão de artigo em periódico B1 ou superior] Será exigida de cada aluno de Doutorado a comprovação da submissão de um artigo para periódico classificado no Qualis da Computação em estrato A1, A2 ou B1.

          [DOUTORADO] [Aceitação de artigo B2 ou superior] Será exigida de cada aluno de Doutorado a comprovação da aceitação de um artigo em estrato superior ou igual a B2.

          Em cada um desses casos, a comprovação do cumprimento da exigência correspondente deverá ser apresentada no máximo até a data do pedido de banca. A banca não será aprovada e a defesa não será permitida sem a devida comprovação do cumprimento da respectiva exigência. Caso mais de um discente seja coautor do mesmo artigo, esse artigo só poderá ser utilizado para efeito de cumprimento da exigência para um único aluno.

          No caso de alunos de Doutorado que tenham concluído o Mestrado anteriormente em nosso programa, o artigo usado para cumprir a exigência de publicação do Mestrado não poderá ser aproveitado para cumprir exigências do Doutorado.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ prof_email }}",
        subject_template: "Prazo para realização de {{ phase_name }} de seu orientando {{ name }}",
        body_template: <<~LIQUID
          {{ prof_name }}

          Lembramos que vence/venceu em {{ due_date | localize: 'longdate' }} o prazo para {{ phase_name }} de seu orientando {{ name }}.

          Para dar entrada de qualquer pedido na secretaria referente a banca ou prorrogação, é preciso observar a data limite (sexta-feira que antecede a última quarta-feira do mês de {{ due_date | localize: 'monthyear' }}). Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso seu aluno já tenha realizado os procedimentos para o cumprimento dessa etapa, favor desconsiderar essa mensagem.

          ------

          Lembramos que para pedido de banca de dissertação, tese ou exame de qualificação, há exigências de publicações, conforme detalhes abaixo. Para comprovar o cumprimento de alguma dessas exigências, o aluno deve enviar por email para a secretaria o artigo aceito ou submetido e o respectivo comprovante a qualquer momento (não é necessário esperar o pedido de banca).

          ------

          [MESTRADO] [Submissão de artigo B4 ou superior] Será exigida de cada aluno de Mestrado a submissão de um artigo completo para veículo classificado no Qualis da Computação em estrato superior ou igual a B4.

          [DOUTORADO] [Submissão de artigo B4 ou superior (p/ defesa de EQ] Será exigida de cada aluno de Doutorado a submissão de um artigo completo para um veículo classificado no Qualis da Computação em estrato superior ou igual a B4, como requisito prévio necessário para a realização do exame de qualificação.

          [DOUTORADO] [Submissão de artigo em periódico B1 ou superior] Será exigida de cada aluno de Doutorado a comprovação da submissão de um artigo para periódico classificado no Qualis da Computação em estrato A1, A2 ou B1.

          [DOUTORADO] [Aceitação de artigo B2 ou superior] Será exigida de cada aluno de Doutorado a comprovação da aceitação de um artigo em estrato superior ou igual a B2.

          Em cada um desses casos, a comprovação do cumprimento da exigência correspondente deverá ser apresentada no máximo até a data do pedido de banca. A banca não será aprovada e a defesa não será permitida sem a devida comprovação do cumprimento da respectiva exigência. Caso mais de um discente seja coautor do mesmo artigo, esse artigo só poderá ser utilizado para efeito de cumprimento da exigência para um único aluno.

          No caso de alunos de Doutorado que tenham concluído o Mestrado anteriormente em nosso programa, o artigo usado para cumprir a exigência de publicação do Mestrado não poderá ser aproveitado para cumprir exigências do Doutorado.
        LIQUID
      }
    },
    { name: "CORD: Alunos ainda não desligados [Agendamento sugerido: Mensal 17d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 2).map(&:email).join(';') %>",
        body_template: <<~ERB
          Prezado Coordenador,

          Informamos que os seguintes alunos pediram banca há mais de 45 dias, mas ainda não foram desligados no SAPOS:

          <% records.each do |record| %>
              - <%= record['name'] %> (<%= record['email'] %>)
          <% end %>
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        body_template: <<~LIQUID
          Prezado Coordenador,

          Informamos que os seguintes alunos pediram banca há mais de 45 dias, mas ainda não foram desligados no SAPOS:

          {% for record in records %}
              - {{ record.name }} ({{ record.email }})
          {% endfor %}
        LIQUID
      }
    },
    { name: "CORD: Número de alunos ativos [Agendamento sugerido: Semestral 3M]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 2).map(&:email).join(';') %>",
        body_template: <<~ERB
          Prezado Coordenador

          Informamos que o número de alunos ativos da pós-graduação é:

          <% records.each do |record| %>
            - <%= record['level'] %> (<%= record['num_alunos'] %>)
          <% end %>
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        body_template: <<~LIQUID
          Prezado Coordenador

          Informamos que o número de alunos ativos da pós-graduação é:

          {% for record in records %}
            - {{ record.level }} ({{ record.num_alunos }})
          {% endfor %}
        LIQUID
      }
    },
    { name: "ALUNOS: Fim da validade de trancamento [Agendamento sugerido: Semestral -20d]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Informamos que a validade do seu trancamento termina no final do mês. Favor comparecer à secretaria na data da matrícula de alunos antigos
          para regularizar sua situação.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Fim da validade do seu trancamento",
        body_template: <<~LIQUID
          {{ name }}

          Informamos que a validade do seu trancamento termina no final do mês. Favor comparecer à secretaria na data da matrícula de alunos antigos
          para regularizar sua situação.
        LIQUID
      }
    },
    { name: "CORD: Fim da validade de trancamentos [Agendamento sugerido: Semestral -9d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 2).map(&:email).join(';') %>",
        body_template: <<~ERB
          Prezado Coordenador

          Informamos que a validade do trancamento dos alunos abaixo relacionados termina no final do mês.
          Aproveitamos para informar que todos eles foram notificados de que devem se matricular para regularizar sua situação.

          <% records.each do |record| %>
              - <%= record['name'] %> - <%= record['enrollment_number'] %> - <%= record['email'] %>
          <% end %>
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        body_template: <<~LIQUID
          Prezado Coordenador

          Informamos que a validade do trancamento dos alunos abaixo relacionados termina no final do mês.
          Aproveitamos para informar que todos eles foram notificados de que devem se matricular para regularizar sua situação.

          {% for record in records %}
              - {{ record.name }} - {{ record.enrollment_number }} - {{ record.email }}
          {% endfor %}
        LIQUID
      }
    },
    { name: "ALUNOS: seminários pendente",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Lembramos que a disciplina de Seminários é obrigatória e não vale créditos. Alunos de Doutorado que já tiverem cursado a disciplina durante o Mestrado devem cursá-la novamente no Doutorado. Recomenda-se que essa disciplina seja cursada no início do curso.

          Consulte o período para inclusão de disciplinas no site.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que a disciplina de Seminários é obrigatória e não vale créditos. Alunos de Doutorado que já tiverem cursado a disciplina durante o Mestrado devem cursá-la novamente no Doutorado. Recomenda-se que essa disciplina seja cursada no início do curso.

          Consulte o período para inclusão de disciplinas no site.
        LIQUID
      }
    },
    { name: "ALUNOS: inscrição pendente",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('nome') %>

          Tivemos a inscrição em disciplinas, porém não identificamos a sua inscrição. Iremos abrir o Sapos novamente hoje e amanhã para acolher a sua inscrição. Caso você não esteja conseguindo fazer login no Sapos, entre em contato com a secretaria urgentemente informando seu e-mail.

          Caso a inscrição não seja realizada, sua matrícula será trancada. Contudo, se você estiver no primeiro semestre do curso ou se você já tiver trancado matrícula anteriormente, sua matrícula será cancelada, pois é vedado o trancamento de matrícula no período de ingresso no curso e o trancamento de matrícula por mais de um período.

          Por favor, entre em contato com a secretaria do curso imediatamente confirmando o trancamento/cancelamento da matrícula, se esse for o caso.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ nome }}

          Tivemos a inscrição em disciplinas, porém não identificamos a sua inscrição. Iremos abrir o Sapos novamente hoje e amanhã para acolher a sua inscrição. Caso você não esteja conseguindo fazer login no Sapos, entre em contato com a secretaria urgentemente informando seu e-mail.

          Caso a inscrição não seja realizada, sua matrícula será trancada. Contudo, se você estiver no primeiro semestre do curso ou se você já tiver trancado matrícula anteriormente, sua matrícula será cancelada, pois é vedado o trancamento de matrícula no período de ingresso no curso e o trancamento de matrícula por mais de um período.

          Por favor, entre em contato com a secretaria do curso imediatamente confirmando o trancamento/cancelamento da matrícula, se esse for o caso.
        LIQUID
      }
    },
    { name: "ALUNOS: Lembrete de inscrição em disciplinas [Agendamento sugerido: Semestral -1M]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('nome') %>

          Lembramos que a inscrição em disciplinas está se aproximando. Ela é obrigatória enquanto você não tiver entrado com pedido de banca. Mesmo que você já tenha terminado todos os créditos, você deve se inscrever em Pesquisa de Tese (para alunos de doutorado) ou Pesquisa de Dissertação (para alunos de mestrado).

          Confira as datas da inscrição em disciplinas no nosso calendário.

          A inscrição em disciplinas deve ser realizada acessando o Sapos (http://sapos.ic.uff.br) nos dias informados no calendário.

          Lembre-se: a inscrição em disciplinas é seu vínculo oficial com o curso, e deve ser renovada a cada semestre. Alunos que não se inscreverem em disciplinas terão a matrícula trancada automaticamente (com direito a retorno apenas no semestre seguinte), ou cancelada, caso já tenham ficado 1 semestre trancados.

          Att, Secretaria
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ nome }}

          Lembramos que a inscrição em disciplinas está se aproximando. Ela é obrigatória enquanto você não tiver entrado com pedido de banca. Mesmo que você já tenha terminado todos os créditos, você deve se inscrever em Pesquisa de Tese (para alunos de doutorado) ou Pesquisa de Dissertação (para alunos de mestrado).

          Confira as datas da inscrição em disciplinas no nosso calendário.

          A inscrição em disciplinas deve ser realizada acessando o Sapos (http://sapos.ic.uff.br) nos dias informados no calendário.

          Lembre-se: a inscrição em disciplinas é seu vínculo oficial com o curso, e deve ser renovada a cada semestre. Alunos que não se inscreverem em disciplinas terão a matrícula trancada automaticamente (com direito a retorno apenas no semestre seguinte), ou cancelada, caso já tenham ficado 1 semestre trancados.

          Att, Secretaria
        LIQUID
      }
    },
    { name: "CORD: Alunos que não se inscreveram em disciplinas [Agendamento sugerido: Semestral 5d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 2).map(&:email).join(';') %>",
        body_template: <<~ERB
          Prezado Coordenador,

          Informamos que os alunos abaixo não se se inscreveram em disciplinas:

          <% records.each do |record| %>
              - <%= record['nome'] %> (<%= record['matricula'] %>), status da matrícula: (<%= record['nome'] %>), data de admissão: <%= localize(record['ingresso'], :monthyear) %>
          <% end %>
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        body_template: <<~LIQUID
          Prezado Coordenador,

          Informamos que os alunos abaixo não se se inscreveram em disciplinas:

          {% for record in records %}
              - {{ record.nome }} ({{ record.matricula }}), status da matrícula: ({{ record.nome }}), data de admissão: {{ ingresso | localize: 'monthyear' }}
          {% endfor %}
        LIQUID
      }
    },
    { name: "ALUNOS: estágio de docência pendente",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Tendo em vista que você foi contemplado com bolsa de doutorado, avisamos que bolsistas de doutorado CAPES PROEX devem realizar estágio em docência em dois semestres de vigência da bolsa. Não há impedimento para que um bolsista exerça as atividades do estágio em docência com seu próprio orientador. A disciplina associada ao estágio em docência não será contabilizada para efeito do número mínimo de disciplinas a serem cursadas a cada período.

          Consulte o período para inclusão de disciplinas no site.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ name }}

          Tendo em vista que você foi contemplado com bolsa de doutorado, avisamos que bolsistas de doutorado CAPES PROEX devem realizar estágio em docência em dois semestres de vigência da bolsa. Não há impedimento para que um bolsista exerça as atividades do estágio em docência com seu próprio orientador. A disciplina associada ao estágio em docência não será contabilizada para efeito do número mínimo de disciplinas a serem cursadas a cada período.

          Consulte o período para inclusão de disciplinas no site.
        LIQUID
      }
    },
    { name: "CORD: Bolsas não alocadas [Agendamento sugerido: Mensal 2d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 2).map(&:email).join(';') %>",
        body_template: <<~ERB
          Prezado Coordenador

          Abaixo estão listados as bolsas que estão disponíveis atualmente:

          <% records.each do |record| %>
            - <%= record['scholarship_number'] %>
          <% end %>
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        body_template: <<~LIQUID
          Prezado Coordenador

          Abaixo estão listados as bolsas que estão disponíveis atualmente:

          {% for record in records %}
            - {{ record.scholarship_number }}
          {% endfor %}
        LIQUID
      }
    },
    { name: "SEC: Alunos que devem entregar a proposta de dissertação [Agendamento sugerido: Semestral 19d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 3).map(&:email).join(';') %>",
        body_template: <<~ERB
          Secretaria,

          Informamos que os seguintes alunos devem entregar as suas propostas de dissertação em até 30 dias após o início das aulas:

          <% records.each do |record| %>
              - <%= record['name'] %> (<%= record['enrollment_number'] %>)
          <% end %>

          Todos esses alunos acabaram de ser notificados que devem fazer essa entrega.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        body_template: <<~LIQUID
          Secretaria,

          Informamos que os seguintes alunos devem entregar as suas propostas de dissertação em até 30 dias após o início das aulas:

          {% for record in records %}
              - {{ record.name }} ({{ record.enrollment_number }})
          {% endfor %}

          Todos esses alunos acabaram de ser notificados que devem fazer essa entrega.
        LIQUID
      }
    },
    { name: "ALUNOS: Alunos que devem entregar a proposta de dissertação [Agendamento sugerido: Semestral 19d]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Lembramos que você tem até 30 dias a partir do início das aulas para entregar a sua proposta de dissertação na secretaria.

          Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado a entrega, favor desconsiderar essa mensagem.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que você tem até 30 dias a partir do início das aulas para entregar a sua proposta de dissertação na secretaria.

          Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado a entrega, favor desconsiderar essa mensagem.
        LIQUID
      }
    },
    { name: "CORD: Disciplinas sem alunos [Agendamento sugerido: Semestral 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 2).map(&:email).join(';') %>",
        body_template: <<~ERB
          Prezado Coordenador,

          Informamos que as seguintes disciplinas não têm nenhum aluno matriculado:

          <% records.each do |record| %>
            - <%= record['disciplina'] %>, <%= record['year'] %>/<%= record['semester'] %> (<%= record['professor'] %>)
          <% end %>
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        body_template: <<~LIQUID
          Prezado Coordenador,

          Informamos que as seguintes disciplinas não têm nenhum aluno matriculado:

          {% for record in records %}
            - {{ record.disciplina }}, {{ record.year }}/{{ record.semester }} ({{ record.professor }})
          {% endfor %}
        LIQUID
      }
    },
    { name: "ALUNOS: inscrição incompleta (bolsistas)",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Alunos bolsistas que ainda não tiverem concluído os créditos deverão cursar pelo menos 12 créditos (3 disciplinas) ou o que falta para completar 24 créditos, o que for menor. Contudo, neste semestre você está inscrito(a) em somente <%= var('total_creditos') %> creditos.

          Portanto, é necessário que você se inscreva em mais disciplinas para completar os 12 crétidos neste período ou o total de 24 créditos considerando as disciplinas que você já foi aprovado(a) e as que está inscrito(a) neste período. Note que a disciplina de "Seminários" não contabiliza créditos.

          O pedido de adição deverá ser feito pelo SAPOS. Caso essa pendência não seja regularizada imediatamente, sua matrícula será trancada. Caso você esteja no primeiro período ou já tenha trancado anteriormente, sua matrícula será cancelada.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ name }}

          Alunos bolsistas que ainda não tiverem concluído os créditos deverão cursar pelo menos 12 créditos (3 disciplinas) ou o que falta para completar 24 créditos, o que for menor. Contudo, neste semestre você está inscrito(a) em somente {{ total_creditos }} creditos.

          Portanto, é necessário que você se inscreva em mais disciplinas para completar os 12 crétidos neste período ou o total de 24 créditos considerando as disciplinas que você já foi aprovado(a) e as que está inscrito(a) neste período. Note que a disciplina de "Seminários" não contabiliza créditos.

          O pedido de adição deverá ser feito pelo SAPOS. Caso essa pendência não seja regularizada imediatamente, sua matrícula será trancada. Caso você esteja no primeiro período ou já tenha trancado anteriormente, sua matrícula será cancelada.
        LIQUID
      }
    },
    { name: "ALUNOS: inscrição incompleta (não bolsistas)",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Alunos não bolsistas que ainda não tiverem concluído os créditos deverão cursar pelo menos 8 créditos (2 disciplinas) ou o que falta para completar 24 créditos, o que for menor. Contudo, neste semestre você está inscrito(a) em somente <%= var('total_creditos') %> creditos.

          Portanto, é necessário que você se inscreva em mais disciplinas para completar os 8 crétidos neste período ou o total de 24 créditos considerando as disciplinas que você já foi aprovado(a) e as que está inscrito(a) neste período. Note que a disciplina de "Seminários" não contabiliza créditos.

          O pedido de adição deverá ser feito pelo SAPOS. Caso essa pendência não seja regularizada imediatamente, sua matrícula será trancada. Caso você esteja no primeiro período ou já tenha trancado anteriormente, sua matrícula será cancelada.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ name }}

          Alunos não bolsistas que ainda não tiverem concluído os créditos deverão cursar pelo menos 8 créditos (2 disciplinas) ou o que falta para completar 24 créditos, o que for menor. Contudo, neste semestre você está inscrito(a) em somente {{ total_creditos }} creditos.

          Portanto, é necessário que você se inscreva em mais disciplinas para completar os 8 crétidos neste período ou o total de 24 créditos considerando as disciplinas que você já foi aprovado(a) e as que está inscrito(a) neste período. Note que a disciplina de "Seminários" não contabiliza créditos.

          O pedido de adição deverá ser feito pelo SAPOS. Caso essa pendência não seja regularizada imediatamente, sua matrícula será trancada. Caso você esteja no primeiro período ou já tenha trancado anteriormente, sua matrícula será cancelada.
        LIQUID
      }
    },
    { name: "ALUNOS: Envio de boletim para ativos regulares [Agendamento sugerido: Semestral 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          Prezado(a) <%=var('name')%>

          Enviamos por este email, em anexo, seu Boletim Escolar da Pós-Graduação.

          Att, Coordenação
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          Prezado(a) {{ name }}

          Enviamos por este email, em anexo, seu Boletim Escolar da Pós-Graduação.

          Att, Coordenação
        LIQUID
      }
    },
    { name: "SEC: Alunos que devem entregar o plano de estudo orientado [Agendamento sugerido: Semestral 19d]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 3).map(&:email).join(';') %>",
        body_template: <<~ERB
          Secretaria,

          Informamos que os seguintes alunos devem entregar o plano de estudo orientado

          <% records.each do |record| %>
              - <%= record['name'] %> (<%= record['enrollment_number'] %>)
          <% end %>

          Todos esses alunos acabaram de ser notificados que devem fazer essa entrega.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        body_template: <<~LIQUID
          Secretaria,

          Informamos que os seguintes alunos devem entregar o plano de estudo orientado

          {% for record in records %}
              - {{ record.name }} ({{ record.enrollment_number }})
          {% endfor %}

          Todos esses alunos acabaram de ser notificados que devem fazer essa entrega.
        LIQUID
      }
    },
    { name: "ALUNOS: Alunos que devem entregar o plano de estudo orientado [Agendamento sugerido: Semestral 19d]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
          <%= var('name') %>

          Lembramos que você tem até 30 dias a partir do início das aulas para entregar o plano de estudo orientado.

          Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado a entrega, favor desconsiderar essa mensagem.
        ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que você tem até 30 dias a partir do início das aulas para entregar o plano de estudo orientado.

          Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado a entrega, favor desconsiderar essa mensagem.
        LIQUID
      }
    },
    { name: "ALUNOS: inscrição inapropriada em pesquisa de tese/dissertação",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
            <%= var('name') %>

            Você se inscreveu em pesquisa de tese/dissertação, porém não cumpriu ainda todos os requisitos para poder fazer inscrição nesse tipo de disciplina. O requisito "<%= var('requisito') %>" ainda está pendente.

            Por favor, remova a inscrição em pesquisa de tese/dissertação e faça a inscrição nas disciplinas que atendam ao requisito que está pendente.

            Caso perceba alguma inconsistência nessa mensagem, por favor, entre em contato com a secretaria do curso imediatamente.
          ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
            {{ name }}

            Você se inscreveu em pesquisa de tese/dissertação, porém não cumpriu ainda todos os requisitos para poder fazer inscrição nesse tipo de disciplina. O requisito "{{ requisito }}" ainda está pendente.

            Por favor, remova a inscrição em pesquisa de tese/dissertação e faça a inscrição nas disciplinas que atendam ao requisito que está pendente.

            Caso perceba alguma inconsistência nessa mensagem, por favor, entre em contato com a secretaria do curso imediatamente.
          LIQUID
      }
    },
    { name: "ALUNOS: documentação pendente [Agendamento sugerido: Semestral 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('email') %>",
        body_template: <<~ERB
            <%= var('name') %>

            Lembramos que, de acordo com o termo de compromisso assinado na matrícula, você deve entregar na secretaria uma cópia do seu diploma de graduação e, para alunos de doutorado, uma cópia do seu diploma de mestrado.

            Vale notar que o pedido de banca de defesa de dissertação ou exame de qualificação só será aceito quando essa documentação for entregue.

            Caso você já tenha enviado a documentação, por favor, entre em contato com a secretaria.
          ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ email }}",
        body_template: <<~LIQUID
            {{ name }}

            Lembramos que, de acordo com o termo de compromisso assinado na matrícula, você deve entregar na secretaria uma cópia do seu diploma de graduação e, para alunos de doutorado, uma cópia do seu diploma de mestrado.

            Vale notar que o pedido de banca de defesa de dissertação ou exame de qualificação só será aceito quando essa documentação for entregue.

            Caso você já tenha enviado a documentação, por favor, entre em contato com a secretaria.
          LIQUID
      }
    },
    { name: "SEC: alunos com documentação pendente [Agendamento sugerido: Semestral 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 3).map(&:email).join(';') %>",
        body_template: <<~ERB
            Secretaria,

            Informamos que os seguintes alunos estão com documentação obrigatória pendente:

            <% records.each do |record| %>
                - <%= record['name'] %> (<%= record['enrollment_number'] %>)
            <% end %>

            Todos esses alunos acabaram de ser notificados sobre a pendência.

            Caso queira incluir algum aluno nessa lista, colocar "DOC PENDENTE" no campo observação da matrícula do referido aluno.
          ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        body_template: <<~LIQUID
            Secretaria,

            Informamos que os seguintes alunos estão com documentação obrigatória pendente:

            {% for record in records %}
                - {{ record.name }} ({{ record.enrollment_number }})
            {% endfor %}

            Todos esses alunos acabaram de ser notificados sobre a pendência.

            Caso queira incluir algum aluno nessa lista, colocar "DOC PENDENTE" no campo observação da matrícula do referido aluno.
          LIQUID
      }
    },
    { name: "SEC: Alunos que não entregaram versão final [Agendamento sugerido: Semanal 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= User.where(:role_id => 3).map(&:email).join(';') %>",
        body_template: <<~ERB
            Secretaria,

            Informamos que o prazo para entrega da versão final dos seguintes alunos se esgotou. Tanto os alunos quanto os orientadores foram alertados sobre o ocorrido.

            <% records.each do |record| %>
                - <%= record['student_name'] %> (<%= record['enrollment_number'] %>, defesa em <%= localize(record['thesis_defense_date'],:defaultdate) %>)
            <% end %>

            Caso algum aluno dessa lista já tenha entregue a versão final, colocar "VF OK" na observação da realização da etapa Pedido de Banca do referido aluno.
          ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        body_template: <<~LIQUID
            Secretaria,

            Informamos que o prazo para entrega da versão final dos seguintes alunos se esgotou. Tanto os alunos quanto os orientadores foram alertados sobre o ocorrido.

            {% for record in records %}
                - {{ record.student_name }} ({{ record.enrollment_number }}, defesa em {{ record.thesis_defense_date | localize: 'defaultdate' }})
            {% endfor %}

            Caso algum aluno dessa lista já tenha entregue a versão final, colocar "VF OK" na observação da realização da etapa Pedido de Banca do referido aluno.
          LIQUID
      }
    },
    { name: "ALUNOS: Prazo vencido para entrega da versão final da dissertação/tese [Agendamento sugerido: Semanal 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('student_email') %>",
        body_template: <<~ERB
            <%= var('student_name') %>

            Lembramos que venceu o prazo para entregar a versão final da sua tese/dissertação, defendida em <%= localize(var('thesis_defense_date'),:defaultdate) %>.

            Entre em contato com a secretaria imediatamente, apresentando uma carta em pdf com a justificativa do atraso, uma solicitação de prazo adicional de, no máximo, 15 dias, e a ciência de que será jubilado e perderá o título caso não cumpra o prazo solicitado. Essa carta deve ser assinada tanto pelo aluno quanto pelo orientador.


            Caso você já tenha entregue a versão final ou já tenha entrado em contato com a secretaria, favor desconsiderar essa mensagem.
          ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ student_email }}",
        body_template: <<~LIQUID
            {{ student_name }}

            Lembramos que venceu o prazo para entregar a versão final da sua tese/dissertação, defendida em {{ thesis_defense_date | localize: 'defaultdate' }}.

            Entre em contato com a secretaria imediatamente, apresentando uma carta em pdf com a justificativa do atraso, uma solicitação de prazo adicional de, no máximo, 15 dias, e a ciência de que será jubilado e perderá o título caso não cumpra o prazo solicitado. Essa carta deve ser assinada tanto pelo aluno quanto pelo orientador.


            Caso você já tenha entregue a versão final ou já tenha entrado em contato com a secretaria, favor desconsiderar essa mensagem.
          LIQUID
      }
    },
    { name: "PROFS: Prazo vencido para entrega da versão final da dissertação/tese [Agendamento sugerido: Semanal 0]",
      before: {
        template_type: "ERB",
        to_template: "<%= var('advisor_email') %>",
        body_template: <<~ERB
            <%= var('advisor_name') %>

            Lembramos que venceu o prazo para entregar a versão final da tese/dissertação do seu orientando <%= var('student_name') %>, defendida em <%= localize(var('thesis_defense_date'),:defaultdate) %>.

            O aluno deve entrar em contato com a secretaria imediatamente, apresentando uma carta em pdf com a justificativa do atraso, uma solicitação de prazo adicional de, no máximo, 15 dias, e a ciência de que será jubilado e perderá o título caso não cumpra o prazo solicitado. Essa carta deve ser assinada tanto pelo aluno quanto pelo orientador.

            Caso o aluno já tenha entregue a versão final ou já tenha entrado em contato com a secretaria, favor desconsiderar essa mensagem.
          ERB
      },
      after: {
        template_type: "Liquid",
        to_template: "{{ advisor_email }}",
        body_template: <<~LIQUID
            {{ advisor_name }}

            Lembramos que venceu o prazo para entregar a versão final da tese/dissertação do seu orientando {{ student_name }}, defendida em {{ thesis_defense_date | localize: 'defaultdate' }}.

            O aluno deve entrar em contato com a secretaria imediatamente, apresentando uma carta em pdf com a justificativa do atraso, uma solicitação de prazo adicional de, no máximo, 15 dias, e a ciência de que será jubilado e perderá o título caso não cumpra o prazo solicitado. Essa carta deve ser assinada tanto pelo aluno quanto pelo orientador.

            Caso o aluno já tenha entregue a versão final ou já tenha entrado em contato com a secretaria, favor desconsiderar essa mensagem.
          LIQUID
      }
    },
  ]

  # <%= var(' a ') %>
  def up
    TRANSFORMATIONS.each do |transform|
      puts transform[:name]
      notification = Notification.where(transform[:before])
      puts (notification.count > 0 ? "..Found" : "..Not found")
      notification.update!(transform[:after])
    end
  end

  def down
    TRANSFORMATIONS.each do |transform|
      puts transform[:name]
      notification = Notification.where(transform[:after])
      puts (notification.count > 0 ? "..Found" : "..Not found")
      notification.update!(transform[:before])
    end
  end  
end

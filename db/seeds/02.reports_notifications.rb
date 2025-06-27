# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

is_sqlite = ActiveRecord::Base.connection.adapter_name.downcase.starts_with? "sqlite"


ReportConfiguration.create([
  { name: "Boletim", scale: 1, x: 0, y: 0, order: 1,
    signature_type: :qr_code,
    use_at_report: false,
    use_at_transcript: false,
    use_at_grades_report: true,
    use_at_schedule: false,
    use_at_assertion: false,
    expiration_in_months: 12,
    text: <<~TEXT
      <NOME DA UNIVERSIDADE>
      <NOME DO INSTITUTO>
      <NOME DO PROGRAMA>
    TEXT
  },
  { name: "Histórico", scale: 0.45, x: 5, y: 12, order: 1,
    signature_type: :qr_code,
    use_at_report: false,
    use_at_transcript: true,
    use_at_grades_report: false,
    use_at_schedule: false,
    use_at_assertion: false,
    expiration_in_months: 12,
    text: <<~TEXT
      <NOME DA UNIVERSIDADE>
      <NOME DO INSTITUTO>
      <NOME DO PROGRAMA>
    TEXT
  },
  { name: "Padrão", scale: 1, x: 0, y: 0, order: 1,
    signature_type: :no_signature,
    use_at_report: true,
    use_at_transcript: false,
    use_at_grades_report: false,
    use_at_schedule: true,
    use_at_assertion: false,
    expiration_in_months: nil,
    text: <<~TEXT
      <NOME DA UNIVERSIDADE>
      <NOME DO INSTITUTO>
      <NOME DO PROGRAMA>
    TEXT
  },
  { name: "Declaração", scale: 1, x: 0, y: 0, order: 1,
    signature_type: :manual,
    use_at_report: false,
    use_at_transcript: false,
    use_at_grades_report: false,
    use_at_schedule: false,
    use_at_assertion: true,
    expiration_in_months: nil,
    text: <<~TEXT
      <NOME DA UNIVERSIDADE>
      <NOME DO INSTITUTO>
      <NOME DO PROGRAMA>
    TEXT
 },
])

# Queries and notifications
queries = [
  { name: "Etapas vencidas (alunos)",
    description: "Etapas de banca ou EQ vencidas. Lista somente os alunos.",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      }
    ],
    notifications: [
      { title: "SEC: Etapas vencidas [Agendamento sugerido: Mensal 4d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "4d",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        subject_template: "Alunos com etapa vencida",
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
      { title: "ALUNOS: Etapas vencidas no mês seguinte [Agendamento sugerido: Mensal 9d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "1M",
        individual: true,
        has_grades_report_pdf_attachment: false,
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
    ],
    sql: <<~SQL
      SELECT students.name AS name,
            students.email AS email,
            phases.name AS phase_name,
            phase_completions.due_date AS due_date
      FROM phase_completions
          INNER JOIN enrollments ON enrollments.id = phase_completions.enrollment_id
          INNER JOIN students ON students.id = enrollments.student_id
          INNER JOIN phases ON phases.id = phase_completions.phase_id
          INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
      WHERE due_date <= :data_consulta
      AND enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND enrollment_statuses.name = "Regular" /* Alunos regulares */
      AND completion_date IS NULL
      /* Somente banca, EQ ou prova de inglês */
      AND (
        phases.name = "Pedido de Banca"
        OR phases.name = "Prova de Inglês"
        OR (
          phases.name = "Exame de Qualificação"
          AND (enrollments.obs IS NULL OR enrollments.obs NOT LIKE '%PEQ%')
        )
      )
    SQL
  },
  { name: "Etapas vencidas (orientadores)",
    description: "Etapas de banca ou EQ vencidas. Lista os alunos e os orientadores.",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [
      { title: "PROFS: Etapas vencidas no mês seguinte [Agendamento sugerido: Mensal 9d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "1M",
        individual: true,
        has_grades_report_pdf_attachment: false,
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
    ],
    sql: <<~SQL
      SELECT students.name AS name,
             students.email AS email,
             professors.name AS prof_name,
             professors.email AS prof_email,
             phases.name AS phase_name,
             due_date AS due_date
      FROM phase_completions
           INNER JOIN enrollments ON enrollments.id = phase_completions.enrollment_id
           INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
           INNER JOIN students ON students.id = enrollments.student_id
           INNER JOIN advisements ON advisements.enrollment_id = enrollments.id
           INNER JOIN professors ON professors.id = advisements.professor_id
           INNER JOIN phases ON phases.id = phase_completions.phase_id
      WHERE due_date<=:data_consulta
      AND enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND enrollment_statuses.name = "Regular"
      AND completion_date IS NULL
      /* Somente banca, EQ ou prova de inglês */
      AND (
        phases.name = "Pedido de Banca"
        OR phases.name = "Prova de Inglês"
        OR (
          phases.name = "Exame de Qualificação"
          AND (enrollments.obs IS NULL OR enrollments.obs NOT LIKE '%PEQ%')
        )
      )
    SQL
  },
  { name: "Alunos ainda não desligados",
    description: "",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      }
    ],
    notifications: [
      { title: "CORD: Alunos ainda não desligados [Agendamento sugerido: Mensal 17d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "-2M",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        subject_template: "Alunos ainda não desligados",
        body_template: <<~LIQUID
          Prezado Coordenador,

          Informamos que os seguintes alunos pediram banca há mais de 45 dias, mas ainda não foram desligados no SAPOS:

          {% for record in records %}
              - {{ record.name }} ({{ record.email }})
          {% endfor %}
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT students.email AS email,
          students.name AS name,
          due_date AS due_date
      FROM phase_completions
          INNER JOIN enrollments ON enrollments.id = phase_completions.enrollment_id
          INNER JOIN students ON students.id = enrollments.student_id
          INNER JOIN accomplishments ON enrollments.id = accomplishments.enrollment_id
          INNER JOIN phases pc_phases ON pc_phases.id = phase_completions.phase_id
          INNER JOIN phases a_phases ON a_phases.id = accomplishments.phase_id
          INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
      WHERE completion_date<=:data_consulta
      AND enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND pc_phases.name = "Pedido de Banca"
      AND a_phases.name = "Pedido de Banca"
      AND enrollment_statuses.name = "Regular"
      /* Desconsidera alunos que foram aprovados condicionalmente.
      Para esses casos, o desligamento só ocorre quando a ata
      com a validação das restrições é engregue */
      AND (accomplishments.obs IS NULL OR accomplishments.obs NOT LIKE '%ACR%')
    SQL
  },
  { name: "Número de alunos ativos",
    description: "",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      }
    ],
    notifications: [
      { title: "CORD: Número de alunos ativos [Agendamento sugerido: Semestral 3M]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "3M",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        subject_template: "Total de alunos ativos",
        body_template: <<~LIQUID
          Prezado Coordenador

          Informamos que o número de alunos ativos da pós-graduação é:

          {% for record in records %}
            - {{ record.level }} ({{ record.num_alunos }})
          {% endfor %}
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT count(*) AS num_alunos,
          levels.name AS level
      FROM enrollments, levels, enrollment_statuses
      WHERE enrollments.id NOT IN (SELECT enrollment_id
                                   FROM dismissals
                                   WHERE date < :data_consulta)
      AND admission_date < :data_consulta
      AND enrollment_statuses.name = "Regular"
      AND enrollments.level_id = levels.id
      AND enrollments.enrollment_status_id = enrollment_statuses.id
      GROUP BY level_id
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Fim da validade de trancamentos",
    description: "",
    params: [
      {
        name: "ano_semestre_anterior",
        value_type: "Integer"
      },
      {
        name: "numero_semestre_anterior",
        value_type: "Integer"
      }
    ],
    notifications: [
      {
        title: "ALUNOS: Fim da validade de trancamento [Agendamento sugerido: Semestral -20d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "2",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Fim da validade do seu trancamento",
        body_template: <<~LIQUID
          {{ name }}

          Informamos que a validade do seu trancamento termina no final do mês. Favor comparecer à secretaria na data da matrícula de alunos antigos
          para regularizar sua situação.
        LIQUID
      },
      {
        title: "CORD: Fim da validade de trancamentos [Agendamento sugerido: Semestral -9d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "2",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        subject_template: "Alunos cujo trancamento expira no final do mês",
        body_template: <<~LIQUID
          Prezado Coordenador

          Informamos que a validade do trancamento dos alunos abaixo relacionados termina no final do mês.
          Aproveitamos para informar que todos eles foram notificados de que devem se matricular para regularizar sua situação.

          {% for record in records %}
              - {{ record.name }} - {{ record.enrollment_number }} - {{ record.email }}
          {% endfor %}
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name,
          s.email,
          e.enrollment_number, eh.year, eh.semester
      FROM students s, enrollments e, enrollment_holds eh
      WHERE s.id = e.student_id
      AND e.id = eh.enrollment_id
      /* Está trancado no momento */
      AND eh.active = 1
      AND eh.year = :ano_semestre_anterior
      AND eh.semester = :numero_semestre_anterior
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos que não se inscreveram em Seminários",
    description: "",
    params: [],
    notifications: [
      {
        title: "ALUNOS: seminários pendente",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Inscrição obrigatória em Seminários",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que a disciplina de Seminários é obrigatória e não vale créditos. Alunos de Doutorado que já tiverem cursado a disciplina durante o Mestrado devem cursá-la novamente no Doutorado. Recomenda-se que essa disciplina seja cursada no início do curso.

          Consulte o período para inclusão de disciplinas no site.
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name AS name, s.email AS email,
             e.enrollment_number AS enrollment_number,
             e.admission_date AS date
      FROM students s, enrollments e, enrollment_statuses es
      WHERE s.id = e.student_id
      AND es.id = e.enrollment_status_id
      AND e.id NOT IN (SELECT enrollment_id
                       FROM dismissals)
      AND e.id NOT IN (SELECT enrollment_ID
                       FROM class_enrollments ce, course_classes cc, courses c, course_types ct
                       WHERE ce.course_class_id = cc.id
                       AND c.id = cc.course_id
                       And c.course_type_id = ct.id
                       AND ct.name = "Seminário"
                       AND (ce.situation = "Aprovado" OR ce.situation = "Incompleto"))
      AND es.name = "Regular"
      ORDER BY admission_date
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos que não se inscreveram em disciplinas",
    description: "Trancamento automático caso não se inscreva. Cancelamento caso já tenha trancado uma vez.",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer"
      }
    ],
    notifications: [
      { title: "ALUNOS: inscrição pendente",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Inscrição obrigatória em disciplinas",
        body_template: <<~LIQUID
          {{ nome }}

          Tivemos a inscrição em disciplinas, porém não identificamos a sua inscrição. Iremos abrir o Sapos novamente hoje e amanhã para acolher a sua inscrição. Caso você não esteja conseguindo fazer login no Sapos, entre em contato com a secretaria urgentemente informando seu e-mail.

          Caso a inscrição não seja realizada, sua matrícula será trancada. Contudo, se você estiver no primeiro semestre do curso ou se você já tiver trancado matrícula anteriormente, sua matrícula será cancelada, pois é vedado o trancamento de matrícula no período de ingresso no curso e o trancamento de matrícula por mais de um período.

          Por favor, entre em contato com a secretaria do curso imediatamente confirmando o trancamento/cancelamento da matrícula, se esse for o caso.
        LIQUID
      },
      { title: "ALUNOS: Lembrete de inscrição em disciplinas [Agendamento sugerido: Semestral -1M]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Lembrete: inscrição em disciplinas no mestrado/doutorado",
        body_template: <<~LIQUID
          {{ nome }}

          Lembramos que a inscrição em disciplinas está se aproximando. Ela é obrigatória enquanto você não tiver entrado com pedido de banca. Mesmo que você já tenha terminado todos os créditos, você deve se inscrever em Pesquisa de Tese (para alunos de doutorado) ou Pesquisa de Dissertação (para alunos de mestrado).

          Confira as datas da inscrição em disciplinas no nosso calendário.

          A inscrição em disciplinas deve ser realizada acessando o Sapos (http://sapos.ic.uff.br) nos dias informados no calendário.

          Lembre-se: a inscrição em disciplinas é seu vínculo oficial com o curso, e deve ser renovada a cada semestre. Alunos que não se inscreverem em disciplinas terão a matrícula trancada automaticamente (com direito a retorno apenas no semestre seguinte), ou cancelada, caso já tenham ficado 1 semestre trancados.

          Att, Secretaria
        LIQUID
      },
      { title: "CORD: Alunos que não se inscreveram em disciplinas [Agendamento sugerido: Semestral 5d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        subject_template: "Alunos que não se inscreveram",
        body_template: <<~LIQUID
          Prezado Coordenador,

          Informamos que os alunos abaixo não se se inscreveram em disciplinas:

          {% for record in records %}
              - {{ record.nome }} ({{ record.matricula }}), status da matrícula: ({{ record.nome }}), data de admissão: {{ record.ingresso | localize: 'monthyear' }}
          {% endfor %}
        LIQUID
      },
    ],
    sql: <<~SQL
      SELECT s.name AS nome,
             s.email AS email,
             e.enrollment_number AS matricula,
             e.admission_date AS ingresso,
             p.name AS orientador
      FROM students s
      INNER JOIN enrollments e ON s.id = e.student_id
      INNER JOIN enrollment_statuses es ON es.id = e.enrollment_status_id
      LEFT JOIN (advisements a, professors p) ON (e.id = a.enrollment_id AND p.id = a.professor_id AND a.main_advisor = true)
      /* aluno regular */
      WHERE es.name = "Regular"
      /* não foi desligado */
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* não pediu banca */
      AND e.id NOT IN (SELECT enrollment_id
                       FROM accomplishments
                       INNER JOIN phases ON phases.id = accomplishments.phase_id
                       WHERE phases.name = "Pedido de Banca")
      /* não está trancado */
      AND e.id NOT IN (SELECT eh.enrollment_id
                       FROM enrollment_holds eh
                       WHERE eh.active = 1
                       AND eh.year = :ano_semestre_atual
                       AND eh.semester = :numero_semestre_atual)
      /* não está inscrito */
      AND e.id NOT IN (SELECT ce.enrollment_id
                       FROM class_enrollments ce, course_classes cc
                       WHERE ce.course_class_id = cc.id
                       AND cc.year = :ano_semestre_atual
                       AND cc.semester = :numero_semestre_atual)
      /* não tem pedido de inscrição */
      AND e.id NOT IN (SELECT er.enrollment_id
                       FROM enrollment_requests er, class_enrollment_requests cer, course_classes cc
                       WHERE er.id = cer.enrollment_request_id
                       AND cer.course_class_id = cc.id
                       AND cc.year = :ano_semestre_atual
                       AND cc.semester = :numero_semestre_atual
                       AND cer.status = "Solicitada"
                       AND cer.action = "Adição")
      ORDER BY s.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos de mestrado com mais de 12 créditos em EO ou Tópicos",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name,
             e.enrollment_number AS enrollment_number,
             SUM(c.credits) AS total_creditos,
             e.obs
      FROM students s, enrollments e, class_enrollments ce,
           courses c, course_types ct, course_classes cc,
           enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.id = ce.enrollment_id
      AND ce.course_class_id = cc.id
      AND cc.course_id = c.id
      AND c.course_type_id = ct.id
      AND e.enrollment_status_id = es.id
      AND e.level_id = l.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND es.name = "Regular"
      AND l.name = "Mestrado"
      AND (ct.name = "Tópicos Avançados" OR ct.name = "Estudo Orientado")
      AND ce.situation != "Reprovado"
      GROUP BY s.name, e.enrollment_number
      HAVING SUM(c.credits) > 12
      ORDER BY s.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos de doutorado com mais de 8 créditos em disciplinas de Tópicos",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name,
             e.enrollment_number AS enrollment_number,
             SUM(c.credits) AS total_creditos,
             e.obs
      FROM students s, enrollments e, class_enrollments ce,
           courses c, course_types ct, course_classes cc,
           enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.id = ce.enrollment_id
      AND ce.course_class_id = cc.id
      AND cc.course_id = c.id
      AND c.course_type_id = ct.id
      AND e.enrollment_status_id = es.id
      AND e.level_id = l.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND es.name = "Regular"
      AND l.name = "Doutorado"
      AND ct.name = "Tópicos Avançados"
      AND ce.situation != "Reprovado"
      GROUP BY s.name, e.enrollment_number
      HAVING SUM(c.credits) > 8
      ORDER BY s.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos de doutorado cursando mais de uma disciplina de tópicos com cada um dos seus orientadores",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name,
            e.enrollment_number AS enrollment_number,
            p.name AS professor,
            SUM(c.credits) AS total_creditos
      FROM students s, enrollments e, `class_enrollments` ce,
          courses c, course_types ct, course_classes cc, professors p,
          enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND e.enrollment_status_id = es.id
      AND e.level_id = l.id
      AND es.name = "Regular"
      AND l.name = "Doutorado"
      AND ce.enrollment_id = e.id
      AND ct.has_score = 1
      AND ct.id = c.course_type_id
      /* Tópicos */
      AND ct.name = "Tópicos Avançados"
      AND c.id = cc.course_id
      AND cc.id = ce.course_class_id
      AND cc.professor_id = p.id
      /* Professor é o orientador */
      AND cc.professor_id IN (SELECT professor_id FROM advisements WHERE enrollment_id = e.id)
      GROUP BY s.name, e.enrollment_number, p.name
      HAVING SUM(c.credits) > 4
      ORDER BY s.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Bolsistas CAPES DS de doutorado que não cursaram 2 Estágio em Docência e não estão inscritos esse período",
    description: "Somente ativos.",
    params: [],
    notifications: [
      { title: "ALUNOS: estágio de docência pendente",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Inscrição Obrigatória em Estágio de Docência",
        body_template: <<~LIQUID
          {{ name }}

          Tendo em vista que você foi contemplado com bolsa de doutorado, avisamos que bolsistas de doutorado CAPES PROEX devem realizar estágio em docência em dois semestres de vigência da bolsa. Não há impedimento para que um bolsista exerça as atividades do estágio em docência com seu próprio orientador. A disciplina associada ao estágio em docência não será contabilizada para efeito do número mínimo de disciplinas a serem cursadas a cada período.

          Consulte o período para inclusão de disciplinas no site.
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name AS name,
             e.enrollment_number AS enrollment_number,
             s.email AS email
      FROM students s, enrollments e, enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.enrollment_status_id = es.id
      AND e.level_id = l.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* Aluno regular */
      AND es.name = "Regular"
      /* Aluno de doutorado */
      AND l.name = "Doutorado"
      /* Bolsista CAPES */
      AND e.id IN (SELECT sd.enrollment_id
                   FROM scholarship_durations sd, scholarships s, sponsors sp, scholarship_types st
                   WHERE sd.scholarship_id = s.id
                   AND s.sponsor_id = sp.id
                   AND s.scholarship_type_id = st.id
                   AND sp.name = "CAPES"
                   AND st.name = "PROEX"
          AND sd.cancel_date IS NULL)
      /* Não cursou dois Estágio em Docência */
      AND e.id NOT IN (SELECT en.id
                FROM enrollments en, class_enrollments ce, courses c, course_types ct, course_classes cc
                WHERE  ct.id = c.course_type_id
                AND c.id = cc.course_id
                AND cc.id = ce.course_class_id
                AND en.id = ce.enrollment_id
                AND (ce.situation = "Aprovado" OR ce.situation = "Incompleto")
                AND ct.name = "Estágio em Docência"
                GROUP BY enrollment_number
                HAVING count(*) >= 2)
      /* Não está inscrito esse período */
      AND e.id NOT IN (SELECT en.id
                FROM enrollments en, class_enrollments ce, courses c, course_types ct, course_classes cc
                WHERE  ct.id = c.course_type_id
                AND c.id = cc.course_id
                AND cc.id = ce.course_class_id
                AND en.id = ce.enrollment_id
                AND ce.situation = "Incompleto"
                AND ct.name = "Estágio em Docência"
                )
      ORDER BY s.name
    SQL
  },
  { name: "Bolsas não alocadas",
    description: "",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      }
    ],
    notifications: [
      { title: "CORD: Bolsas não alocadas [Agendamento sugerido: Mensal 2d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        subject_template: "Bolsas disponíveis",
        body_template: <<~LIQUID
          Prezado Coordenador

          Abaixo estão listados as bolsas que estão disponíveis atualmente:

          {% for record in records %}
            - {{ record.scholarship_number }}
          {% endfor %}
        LIQUID
      }
    ],
    sql: <<~SQL
      /* Bolsas ativas que terminam antes da data desejada */
      SELECT s.scholarship_number, sd.cancel_date AS "data_termino",
             s.end_date AS "validade_da_bolsa",
             sd.end_date AS "validade_alocacao"
      FROM scholarships s, scholarship_durations sd
      WHERE s.id = sd.scholarship_id
      AND (
        s.end_date IS NULL
        OR s.end_date > :data_consulta
      )
      AND sd.end_date < :data_consulta
      AND sd.cancel_date IS NULL

      UNION

      SELECT s.scholarship_number, "não alocada" AS "data_termino",
             s.end_date AS "validade_da_bolsa",
             "não alocada" AS "validade_alocacao"
      FROM scholarships s
      WHERE s.id NOT
      IN (
        SELECT scholarship_id
        FROM scholarship_durations
        WHERE cancel_date IS NULL
      )
      AND (s.end_date IS NULL
      OR s.end_date > :data_consulta)

      UNION

      SELECT s.scholarship_number, "alocada a aluno desligado" AS "data_termino",
             s.end_date AS "validade_da_bolsa",
             sd.end_date AS "validade_alocacao"
      FROM scholarships s, scholarship_durations sd
      WHERE s.id = sd.scholarship_id
      AND s.id IN (
        SELECT scholarship_id
        FROM scholarship_durations
        WHERE cancel_date IS NULL
        AND enrollment_id IN (SELECT enrollment_id FROM dismissals)
      )
    SQL
  },
  { name: "Alunos de mestrado que se inscreveram pela primeira vez em Pesquisa de Dissertação e não possuem orientador",
    description: "Usar para checar se todos entregaram a proposta de dissertação na primeira inscrição em dissertação",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer"
      }
    ],
    notifications: [
      { title: "SEC: Alunos que devem entregar a proposta de dissertação [Agendamento sugerido: Semestral 19d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "19",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        subject_template: "Alunos que devem entregar a proposta de dissertação",
        body_template: <<~LIQUID
          Secretaria,

          Informamos que os seguintes alunos devem entregar as suas propostas de dissertação em até 30 dias após o início das aulas:

          {% for record in records %}
              - {{ record.name }} ({{ record.enrollment_number }})
          {% endfor %}

          Todos esses alunos acabaram de ser notificados que devem fazer essa entrega.
        LIQUID
      },
      { title: "ALUNOS: Alunos que devem entregar a proposta de dissertação [Agendamento sugerido: Semestral 19d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "19",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Prazo para a entrega da proposta de dissertação",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que você tem até 30 dias a partir do início das aulas para entregar a sua proposta de dissertação na secretaria.

          Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado a entrega, favor desconsiderar essa mensagem.
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name, e.enrollment_number, s.email
      FROM students s, enrollments e, enrollment_statuses es
      WHERE s.id = e.student_id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND e.enrollment_status_id = es.id
      AND es.name = "Regular"
      AND e.id NOT IN (SELECT a.enrollment_id FROM advisements a) /* Não tem orientador */

      /* se estiver inscrito em dissertação esse período */
      AND e.id IN (SELECT ce.enrollment_id
            FROM class_enrollments ce, course_classes cc, courses c, course_types ct
            WHERE ce.course_class_id = cc.id
            AND cc.course_id = c.id
            AND c.course_type_id = ct.id
            AND cc.year = :ano_semestre_atual
            AND cc.semester = :numero_semestre_atual
            AND ct.name = "Pesquisa de Dissertação e Tese")
      ORDER BY s.name
    SQL
  },
  { name: "Alunos Ativos",
    description: "Lista os alunos ativos",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.cpf, s.email
      FROM enrollments e, students s, enrollment_statuses es
      WHERE e.id NOT IN (SELECT enrollment_id
                         FROM dismissals)
      AND s.id = e.student_id
      AND e.enrollment_status_id = es.id
      AND es.name = "Regular"
      ORDER BY s.name
    SQL
  },
  { name: "Disciplinas sem notas",
    description: "Listagem das disciplinas para as quais ainda não foram lançadas as notas",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT DISTINCT cc.name AS "nome curso", p.name AS "professor", cc.year, cc.semester
      FROM course_classes cc, professors p, class_enrollments ce,
          courses c, course_types ct
      WHERE cc.professor_id = p.id
      AND ce.course_class_id = cc.id
      AND ce.situation = "Incompleto"
      AND c.id = cc.course_id
      AND c.course_type_id = ct.id
      /* Não é Tese nem Dissertação */
      /* mas pode ser Pesquisa de Tese ou de Dissertação */
      AND ct.name <> "Defesa de Dissertação e Tese"
      ORDER BY p.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Disciplinas sem alunos",
    description: "Listagem de disciplinas sem nenhum aluno inscrito",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer"
      }
    ],
    notifications: [
      { title: "CORD: Disciplinas sem alunos [Agendamento sugerido: Semestral 0]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Coordenação %}",
        subject_template: "[SAPOS] Disciplinas sem alunos matriculados",
        body_template: <<~LIQUID
          Prezado Coordenador,

          Informamos que as seguintes disciplinas não têm nenhum aluno matriculado:

          {% for record in records %}
            - {{ record.disciplina }}, {{ record.year }}/{{ record.semester }} ({{ record.professor }})
          {% endfor %}
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT DISTINCT cc.name AS disciplina, p.name AS professor, cc.year, cc.semester
      FROM course_classes cc, professors p
      WHERE cc.professor_id = p.id
      AND cc.id NOT IN (SELECT course_class_id FROM class_enrollments)
      AND cc.year = :ano_semestre_atual
      AND cc.semester = :numero_semestre_atual
      ORDER BY cc.year, cc.semester, p.name
    SQL
  },
  { name: "Lista de maiores CR de mestrado",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
        e.enrollment_number,
        round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 5) AS cr,
        SUM(c.credits) AS creditos,
        e.admission_date
      FROM students s, enrollments e, class_enrollments ce, courses c,
           course_types ct, course_classes cc, enrollment_statuses es,
           levels l
      WHERE s.id = e.student_id
        AND e.enrollment_status_id = es.id
        AND e.level_id = l.id
        AND es.name = "Regular"
        AND l.name = "Mestrado"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation !=  "Incompleto"
        AND (e.obs NOT LIKE "%%HISTORICO INCOMPLETO%%" OR e.obs IS NULL)
        /* ou está ativo, ou foi desligado por titulação */
        AND ((e.id NOT IN (SELECT enrollment_id from dismissals)) OR
          (e.id IN (SELECT d.enrollment_id
                    FROM dismissals d, dismissal_reasons dr
                    WHERE d.dismissal_reason_id = dr.id
                    AND dr.name = "Titulação")))
      GROUP BY s.name, e.enrollment_number
      ORDER BY cr DESC
    SQL
  },
  { name: "Lista de maiores CR de doutorado",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
             e.enrollment_number,
             round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 5) AS cr,
             SUM(c.credits) AS creditos,
             e.admission_date
      FROM students s, enrollments e, class_enrollments ce, courses c,
           course_types ct, course_classes cc, enrollment_statuses es,
           levels l
      WHERE s.id = e.student_id
        AND e.enrollment_status_id = es.id
        AND e.level_id = l.id
        AND es.name = "Regular"
        AND l.name = "Doutorado"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation !=  "Incompleto"
        AND (e.obs NOT LIKE "%%HISTORICO INCOMPLETO%%" OR e.obs IS NULL)
        /* ou está ativo, ou foi desligado por titulação */
        AND ((e.id NOT IN (SELECT enrollment_id from dismissals)) OR
          (e.id IN (SELECT d.enrollment_id
                    FROM dismissals d, dismissal_reasons dr
                    WHERE d.dismissal_reason_id = dr.id
                    AND dr.name = "Titulação")))
      GROUP BY s.name, e.enrollment_number
      ORDER BY cr DESC
    SQL
  },
  { name: "Alunos de mestrado que irão se matricular em pesquisa de dissertação pela primeira vez",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name,
            e.enrollment_number AS enrollment_number,
            e.admission_date AS date
      FROM students s, enrollments e, enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.enrollment_status_id = es.id
      AND e.level_id = l.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* Aluno regular */
      AND es.name = "Regular"
      /* Aluno de mestrado */
      AND l.name = "Mestrado"
      /* Nunca se matriculou em pesquisa de dissertação */
      AND e.id NOT IN (SELECT enrollment_id
                       FROM class_enrollments ce, course_classes cc, courses c, course_types ct
                       WHERE ce.course_class_id = cc.id
                       AND c.course_type_id = ct.id
                       AND ct.name = "Pesquisa de Dissertação e Tese"
                       AND c.id = cc.course_id)
      /* Já completou os créditos */
      AND e.id IN (SELECT en.id
                   FROM enrollments en, class_enrollments ce, courses c, course_types ct, course_classes cc
                   WHERE ct.has_score = 1
                   AND en.id = ce.enrollment_id
                   AND cc.id = ce.course_class_id
                   AND c.id = cc.course_id
                   AND ct.id = c.course_type_id
                   AND ce.situation = "Aprovado"
                   GROUP BY en.id
                   HAVING SUM( c.credits ) >= 24)
      GROUP BY s.name, e.enrollment_number, e.admission_date
      ORDER BY s.name
    SQL
  },
  { name: "Alunos de uma determinada área de pesquisa",
    description: "",
    params: [
      {
        name: "codigo_area_pesquisa",
        value_type: "Integer"
      }
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS nome, e.enrollment_number, s.email AS email
      FROM students s, enrollments e
      WHERE s.id = e.student_id
      AND e.research_area_id = :codigo_area_pesquisa
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos bolsistas cursando menos créditos do que o determinado",
    description: "Considerando 3 disciplinas (12 créditos) para ambos. Considerando 24 créditos no total para ambos.",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "data_consulta",
        value_type: "Date"
      }
    ],
    notifications: [
      { title: "ALUNOS: inscrição incompleta (bolsistas)",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Inscrição incompleta em disciplinas",
        body_template: <<~LIQUID
          {{ name }}

          Alunos bolsistas que ainda não tiverem concluído os créditos deverão cursar pelo menos 12 créditos (3 disciplinas) ou o que falta para completar 24 créditos, o que for menor. Contudo, neste semestre você está inscrito(a) em somente {{ total_creditos }} creditos.

          Portanto, é necessário que você se inscreva em mais disciplinas para completar os 12 crétidos neste período ou o total de 24 créditos considerando as disciplinas que você já foi aprovado(a) e as que está inscrito(a) neste período. Note que a disciplina de "Seminários" não contabiliza créditos.

          O pedido de adição deverá ser feito pelo SAPOS. Caso essa pendência não seja regularizada imediatamente, sua matrícula será trancada. Caso você esteja no primeiro período ou já tenha trancado anteriormente, sua matrícula será cancelada.
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name AS name,
             s.email AS email,
             e.enrollment_number AS enrollment_number,
             SUM(c.credits) AS total_creditos,
             e.obs
      FROM students s, enrollments e, class_enrollments ce, course_classes cc,
           courses c, course_types ct, enrollment_statuses es
      WHERE s.id = e.student_id
      AND e.id = ce.enrollment_id
      AND ce.course_class_id = cc.id
      AND cc.course_id = c.id
      AND c.course_type_id = ct.id
      AND e.enrollment_status_id = es.id
      AND e.id NOT IN (SELECT d.enrollment_id FROM dismissals d) /* Aluno ativo */
      AND es.name = "Regular" /* Aluno regular */
      AND ct.has_score = 1 /* disciplina com nota */
      AND ct.name != "Estágio em Docência" /* estágio de docência não conta */
      AND cc.year = :ano_semestre_atual
      AND cc.semester = :numero_semestre_atual
      /* Bolsista */
      AND e.id IN (SELECT enrollment_id
                   FROM scholarship_durations
                   WHERE end_date > :data_consulta
                   AND cancel_date IS NULL)
      /* Não completaria os créditos agora se for aprovado em todas as disciplinas */
      AND e.id IN (SELECT e2.id
                FROM enrollments e2, class_enrollments ce2, course_classes cc2, courses c2, course_types ct2
                WHERE e2.id = ce2.enrollment_id
                AND ce2.course_class_id = cc2.id
                AND cc2.course_id = c2.id
                AND c2.course_type_id = ct2.id
                AND ce2.situation != "Reprovado" /* não conta disciplinas que o aluno foi reprovado */
                AND ct2.name != "Estágio em Docência" /* não conta estágio de docência */
                GROUP BY e2.id
                HAVING SUM(c2.credits) < 24)
      GROUP BY s.name, e.enrollment_number
      HAVING SUM(c.credits) < 12
      ORDER BY s.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Alunos não bolsistas cursando menos créditos do que o determinado",
    description: "Considerando 2 disciplinas (8 créditos) para ambos. Considerando 24 créditos no total para ambos.",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer"
      },
      {
        name: "data_consulta",
        value_type: "Date"
      }
    ],
    notifications: [
      { title: "ALUNOS: inscrição incompleta (não bolsistas)",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Inscrição incompleta em disciplinas",
        body_template: <<~LIQUID
          {{ name }}

          Alunos não bolsistas que ainda não tiverem concluído os créditos deverão cursar pelo menos 8 créditos (2 disciplinas) ou o que falta para completar 24 créditos, o que for menor. Contudo, neste semestre você está inscrito(a) em somente {{ total_creditos }} creditos.

          Portanto, é necessário que você se inscreva em mais disciplinas para completar os 8 crétidos neste período ou o total de 24 créditos considerando as disciplinas que você já foi aprovado(a) e as que está inscrito(a) neste período. Note que a disciplina de "Seminários" não contabiliza créditos.

          O pedido de adição deverá ser feito pelo SAPOS. Caso essa pendência não seja regularizada imediatamente, sua matrícula será trancada. Caso você esteja no primeiro período ou já tenha trancado anteriormente, sua matrícula será cancelada.
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name AS name,
             s.email AS email,
             e.enrollment_number AS enrollment_number,
             SUM(c.credits) AS total_creditos,
             e.obs
      FROM students s, enrollments e, class_enrollments ce, course_classes cc,
           courses c, course_types ct, enrollment_statuses es
      WHERE s.id = e.student_id
      AND e.id = ce.enrollment_id
      AND ce.course_class_id = cc.id
      AND cc.course_id = c.id
      AND c.course_type_id = ct.id
      AND e.enrollment_status_id = es.id
      AND e.id NOT IN (SELECT d.enrollment_id FROM dismissals d) /* Aluno ativo */
      AND es.name = "Regular" /* Aluno regular */
      AND ct.has_score = 1 /* disciplina com nota */
      AND ct.name != "Estágio em Docência" /* estágio de docência não conta */
      AND cc.year = :ano_semestre_atual
      AND cc.semester = :numero_semestre_atual
      /* Não bolsista */
      AND e.id NOT IN (SELECT enrollment_id
                       FROM scholarship_durations
                       WHERE end_date > :data_consulta
                       AND cancel_date IS NULL)
      /* Não completaria os créditos agora se for aprovado em todas as disciplinas */
      AND e.id IN (SELECT e2.id
                   FROM enrollments e2, class_enrollments ce2, course_classes cc2, courses c2, course_types ct2
                   WHERE e2.id = ce2.enrollment_id
                   AND ce2.course_class_id = cc2.id
                   AND cc2.course_id = c2.id
                   AND c2.course_type_id = ct2.id
                   AND ce2.situation != "Reprovado" /* não conta disciplinas que o aluno foi reprovado */
                   AND ct2.name != "Estágio em Docência" /* não conta estágio de docência */
                   GROUP BY e2.id
                   HAVING SUM(c2.credits) < 24)
      GROUP BY s.name, e.enrollment_number
      HAVING SUM(c.credits) < 8
      ORDER BY s.name
    SQL
  },
  { name: "Quantidade de Alunos por Área de Pesquisa",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT r.name, COUNT(*)
      FROM enrollments e, research_areas r
      WHERE e.research_area_id = r.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      GROUP BY r.name
    SQL
  },
  { name: "CHECK FIM SEMESTRE - Alunos reprovados por frequencia com nota maior que ZERO",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
             e.enrollment_number,
             cc.name,
             cc.year,
             cc.semester,
             ce.grade
      FROM students s, enrollments e, class_enrollments ce, courses c,
           course_classes cc, enrollment_statuses es
      WHERE s.id = e.student_id
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
        AND ce.enrollment_id = e.id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.disapproved_by_absence = 1
        AND ce.grade > 0
      ORDER BY cc.year, cc.semester, s.name
    SQL
  },
  { name: "Candidatos à Bolsa de MESTRADO NOTA 10",
    description: "Lista os candidatos à bolsa de MESTRADO NOTA 10 que entraram em um determinado ano/semestre (lembrar de mudar o ano/semestre, que está hardcoded na consulta)",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
             e.enrollment_number,
             round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 5) AS cr,
             SUM(c.credits) AS creditos,
             e.admission_date
      FROM students s, enrollments e, class_enrollments ce, courses c,
           course_types ct, course_classes cc, enrollment_statuses es, levels l
      WHERE s.id = e.student_id
        AND e.enrollment_status_id = es.id
        AND e.level_id = l.id
        AND es.name = "Regular"
        AND l.name = "Mestrado"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation !=  "Incompleto"
        AND e.id NOT IN (SELECT enrollment_id from dismissals)
        AND e.admission_date="2022-08-01"
        /* eh bolsista */
        AND e.id IN (SELECT enrollment_id FROM scholarship_durations WHERE cancel_date IS NULL)
      GROUP BY s.name, e.enrollment_number
      ORDER BY cr DESC
    SQL
  },
  { name: "Candidatos à bolsa de DOUTORADO NOTA 10",
    description: "Lista os candidatos à bolsa de DOUTORADO NOTA 10 que entraram em um determinado ano/semestre (lembrar de mudar o ano/semestre, que está hardcoded na consulta)",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
        e.enrollment_number,
        round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 5) AS cr,
        SUM(c.credits) AS creditos,
        e.admission_date
      FROM students s, enrollments e, class_enrollments ce, courses c,
        course_types ct, course_classes cc, enrollment_statuses es, levels l
      WHERE s.id = e.student_id
        AND e.enrollment_status_id = es.id
        AND e.level_id = l.id
        AND es.name = "Regular"
        AND l.name = "Doutorado"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation !=  "Incompleto"
        AND e.id NOT IN (SELECT enrollment_id from dismissals)
        AND e.admission_date="2020-08-01"
        /* eh bolsista */
        AND e.id IN (SELECT enrollment_id FROM scholarship_durations WHERE cancel_date IS NULL)
      GROUP BY s.name, e.enrollment_number
      ORDER BY cr DESC
    SQL
  },
  { name: "Emails dos bolsistas",
    description: "Recupera os emails de todos os bolsistas (mestrado e doutorado)",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.email AS email
      FROM students s, enrollments e, enrollment_statuses es
      WHERE s.id = e.student_id
      AND e.enrollment_status_id = es.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* Aluno regular */
      AND es.name = "Regular"
      /* Bolsista */
      AND e.id IN (SELECT enrollment_id
            FROM scholarship_durations
            WHERE cancel_date IS NULL)
      ORDER BY s.name
    SQL
  },
  { name: "Taxa de Sucesso",
    description: "Consulta retorna número total de matriculados num determinado ano semestre, e também o número de cada tipo de desligamento, sempre contando por data de admissão. Copiar o resultado numa tabela excel para manipular os números.",
    params: [],
    notifications: [],
    sql: <<~SQL
      /* Numero de alunos matriculados em cada nivel por semestre */
      SELECT l.name AS NIVEL,
             e.admission_date AS DATA_MATRICULA,
             "Total Matriculados" AS STATUS,
             COUNT(*) AS NUM_ALUNOS
      FROM enrollments e, levels l, enrollment_statuses es
      WHERE l.id = e.level_id
      AND e.enrollment_status_id = es.id
      AND es.name = "Regular"
      AND e.admission_date > "2010-01-01"
      GROUP BY l.name, e.admission_date

      UNION

      /* Numero de desligamentos, por motivo, de alunos matriculados num determinado ano semestre */
      SELECT l.name AS NIVEL, e.admission_date AS DATA_MATRICULA, dr.name AS STATUS, COUNT(*) AS NUM_ALUNOS
      FROM enrollments e, enrollment_statuses es, dismissals d, dismissal_reasons dr, levels l
      WHERE e.id = d.enrollment_id
      AND e.enrollment_status_id = es.id
      AND d.dismissal_reason_id = dr.id
      AND l.id = e.level_id
      AND es.name = "Regular"
      AND e.admission_date > "2010-01-01"
      GROUP BY l.name, e.admission_date, dr.name
    SQL
  },
  { name: "CHECK MATRÍCULA - Alunos de doutorado que não possuem orientador",
    description: "Usar para checar se todas as orientações de doutorado foram cadastradas após a matrícula",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.email
      FROM students s, enrollments e, enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.level_id = l.id
      AND e.enrollment_status_id = es.id
      AND l.name = "Doutorado"
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND es.name = "Regular" /* Aluno Regular */
      /* Não tem orientador */
      AND e.id NOT IN (SELECT a.enrollment_id FROM advisements a)
      ORDER BY s.name
    SQL
  },
  { name: "Lista de bolsistas de doutorado de maior CR",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
        e.enrollment_number,
        round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 5) AS cr,
        SUM(c.credits) AS creditos,
        e.admission_date, sc.scholarship_number
      FROM students s, enrollments e, class_enrollments ce, courses c,
        course_types ct, course_classes cc, scholarship_durations sd,
        scholarships sc, levels l, enrollment_statuses es
      WHERE s.id = e.student_id
          AND sd.enrollment_id = e.id
        AND sd.scholarship_id = sc.id
        AND e.level_id = l.id
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND l.name = "Doutorado"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation !=  "Incompleto"
        AND e.id NOT IN (SELECT enrollment_id from dismissals)
        /* eh bolsista */
        AND sd.cancel_date IS NULL
      GROUP BY s.name, e.enrollment_number
      ORDER BY cr DESC
    SQL
  },
  { name: "Alunos de mestrado que terminariam os créditos esse semestre mas não cumpririam os requisitos do curso",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name,
             e.enrollment_number AS enrollment_number,
             e.admission_date AS date
      FROM students s, enrollments e, enrollment_statuses es, levels l
      WHERE s.id = e.student_id
      AND e.enrollment_status_id = es.id
      AND e.level_id = l.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* Aluno regular */
      AND es.name = "Regular"
      /* Aluno de mestrado */
      AND l.name = "Mestrado"
      AND (e.obs NOT LIKE "%%BASICAS OK%%" OR e.obs IS NULL)
      AND
      /* Não cursou ou está cursando uma básica de alguma área */
      (e.id NOT IN (SELECT en.id
                    FROM enrollments en, class_enrollments ce, courses c,
                         course_types ct, course_classes cc
                    WHERE ct.id = c.course_type_id
                    AND c.id = cc.course_id
                    AND cc.id = ce.course_class_id
                    AND en.id = ce.enrollment_id
                    AND (ce.situation = "Aprovado" OR ce.situation = "Incompleto")
                    AND ct.name = "Obrigatória de Linha de Pesquisa"
                    GROUP BY enrollment_number
                    HAVING count(*) >= 1)
      OR
      /* Não cursou ou está cursando duas básicas do curso */
      e.id NOT IN (SELECT en.id
                   FROM enrollments en, class_enrollments ce, courses c,
                        course_types ct, course_classes cc
                   WHERE en.id = ce.enrollment_id
                   AND ct.id = c.course_type_id
                   AND c.id = cc.course_id
                   AND cc.id = ce.course_class_id
                   AND (ce.situation =  "Aprovado" OR ce.situation = "Incompleto")
                   AND ct.name = "Obrigatória de Curso"
                   GROUP BY enrollment_number
                   HAVING COUNT( * ) >=2)
      OR
      /* Não cursou ou está cursando Seminários */
      e.id NOT IN (SELECT en.id
                FROM enrollments en, class_enrollments ce, courses c,
                     course_types ct, course_classes cc
                WHERE en.id = ce.enrollment_id
                AND ct.id = c.course_type_id
                AND c.id = cc.course_id
                AND cc.id = ce.course_class_id
                AND (ce.situation =  "Aprovado" OR ce.situation = "Incompleto")
                AND ct.name = "Seminário"
              )
      )
      AND
      /* Vai completar os créditos esse semestre */
      e.id IN (SELECT en.id
               FROM enrollments en, class_enrollments ce, courses c,
                    course_types ct, course_classes cc
               WHERE ct.has_score = 1
               AND en.id = ce.enrollment_id
               AND cc.id = ce.course_class_id
               AND c.id = cc.course_id
               AND ct.id = c.course_type_id
               AND (ce.situation = "Aprovado" OR ce.situation = "Incompleto")
               GROUP BY en.id
               HAVING SUM( c.credits ) >= 32)
      GROUP BY s.name, e.enrollment_number, e.admission_date
      ORDER BY s.name
    SQL
  },
  { name: "Alunos ativos para ControlID",
    description: "Gera lista de alunos ativos para cadastrar no ControlID",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.cpf, e.enrollment_number
      FROM enrollments e, students s, enrollment_statuses es
      WHERE e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND e.enrollment_status_id = es.id
      AND s.id = e.student_id
      AND es.name = "Regular"
      ORDER BY s.name
    SQL
  },
  { name: "Alunos que já trancaram matrícula alguma vez",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
             s.email,
             e.enrollment_number, eh.year, eh.semester
      FROM students s, enrollments e, enrollment_holds eh
      WHERE s.id = e.student_id
      AND e.id = eh.enrollment_id
    SQL
  },
  { name: "Alunos REGULARES ativos",
    description: "Lista de alunos ativos (excluindo alunos avulsos)",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.email, e.enrollment_number
      FROM enrollments e, students s, enrollment_statuses es
      WHERE e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND e.enrollment_status_id = es.id
      AND es.name = "Regular"
      AND s.id = e.student_id
      AND :data_consulta > 1
      ORDER BY s.name
    SQL
  },
  { name: "Número de alunos por nível e sexo",
    description: "",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT count(*) AS num_alunos,
        levels.name AS level, students.sex AS sex
      FROM enrollments, levels, students, enrollment_statuses
      WHERE enrollments.id NOT IN (SELECT enrollment_id
                                   FROM dismissals
                                   WHERE date < :data_consulta)
      AND enrollments.enrollment_status_id = enrollment_statuses.id
      AND students.id = enrollments.student_id
      AND admission_date < :data_consulta
      AND enrollment_statuses.name = "Regular"
      AND enrollments.level_id = levels.id
      GROUP BY level_id, sex
    SQL
  },
  { name: "Número de bolsistas por nível e sexo",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT count(*) AS num_alunos,
             levels.name AS level, students.sex AS sex
      FROM enrollments, levels, students, enrollment_statuses
      WHERE enrollments.id NOT IN (SELECT enrollment_id
                                   FROM dismissals)
      AND enrollments.enrollment_status_id = enrollment_statuses.id
      AND students.id = enrollments.student_id
      AND enrollment_statuses.name = "Regular"
      AND enrollments.level_id = levels.id
      /* Bolsista */
      AND enrollments.id IN (SELECT enrollment_id
                             FROM scholarship_durations
                             WHERE cancel_date IS NULL)
      GROUP BY level_id, sex
    SQL
  },
  { name: "Alunos ativos por país e nível",
    description: "",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT count(*) AS num_alunos,
             levels.name AS level, countries.name AS país
      FROM enrollments, levels, students, states, countries, enrollment_statuses
      WHERE enrollments.id NOT IN (SELECT enrollment_id
                                   FROM dismissals)
      AND enrollments.enrollment_status_id = enrollment_statuses.id
      AND students.id = enrollments.student_id
      AND enrollment_statuses.name = "Regular"
      AND enrollments.level_id = levels.id
      AND students.birth_state_id = states.id
      AND states.country_id = countries.id
      GROUP BY level_id, countries.name
    SQL
  },
  { name: "Alunos de um determinado orientador que já pediu banca mas ainda está ativo",
    description: "Essa consulta visa facilitar checagem de pontos de orientação, pois alunos que já pediram banca não contam mais pontos, mas o sistema não calcula isso de forma automática.",
    params: [
      {
        name: "nome_professor",
        value_type: "String"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, e.enrollment_number, e.thesis_defense_date
      FROM enrollments e, students s, accomplishments a,
           advisements ad, professors p, phases ph
      WHERE s.id = e.student_id
      AND a.enrollment_id = e.id
      /* Alunoe está ativo */
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* Etapa é pedido de banca */
      AND a.phase_id = ph.id
      AND ph.name = "Pedido de Banca"
      AND ad.enrollment_id = e.id
      AND ad.professor_id = p.id
      AND p.name LIKE :nome_professor
    SQL
  },
  { name: "Alunos de um determinado país",
    description: "",
    params: [
      {
        name: "nome_pais",
        value_type: "String",
        default_value: "Brasil"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS aluno, e.enrollment_number AS matrícula, c.name AS país
      FROM enrollments e, students s, countries c, states st
      WHERE s.id = e.student_id
      AND s.birth_state_id = st.id
      AND st.country_id = c.id
      AND c.name = :nome_pais
      ORDER BY s.name
    SQL
  },
  { name: "Lista de Defesas",
    description: "Lista as defesas ordenadas por data",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS ALUNO, e.level_id, e.thesis_title, e.thesis_defense_date, p.name AS ORIENTADOR
      FROM enrollments e, students s, advisements a, professors p
      WHERE s.id = e.student_id
      AND a.enrollment_id = e.id
      AND a.professor_id = p.id
      AND e.id IN (SELECT enrollment_id FROM dismissals)
      AND e.thesis_defense_date IS NOT NULL
      AND e.thesis_defense_date >= "2016-01-01"
      ORDER BY e.thesis_defense_date
    SQL
  },
  { name: "Bolsistas de Doutorado e Orientadores",
    description: "Lista os alunos de doutorado bolsistas e seus orientadores principais",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT students.name AS name,
             professors.name AS prof_name
      FROM enrollments
           INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
           INNER JOIN levels ON levels.id = enrollments.level_id
           INNER JOIN students ON students.id = enrollments.student_id
           LEFT OUTER JOIN advisements ON advisements.enrollment_id = enrollments.id
           INNER JOIN professors ON professors.id = advisements.professor_id
      WHERE enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND enrollment_statuses.name = "Regular"
      /* Apenas alunos de doutorado */
      AND levels.name = "Doutorado"
      /* Listas apenas Orientador Principal */
      AND advisements.main_advisor = 1
      /* Bolsista */
      AND enrollments.id IN (SELECT enrollment_id
                             FROM scholarship_durations
                             WHERE end_date > :data_consulta
                             AND cancel_date IS NULL)

      UNION
      /* Alunos bolsistas de doutorado ainda sem orientador */
      SELECT students.name AS name, "--" AS prof_name
      FROM enrollments
           INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
           INNER JOIN levels ON levels.id = enrollments.level_id
           INNER JOIN students ON students.id = enrollments.student_id
      WHERE
      enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND enrollment_statuses.name = "Regular"
      /* Apenas alunos de doutorado */
      AND levels.name = "Doutorado"
      /* Bolsista */
      AND enrollments.id IN (SELECT enrollment_id
                             FROM scholarship_durations
                             WHERE end_date > :data_consulta
                             AND cancel_date IS NULL)
      /* Não está entre os que possuem orientador */
      AND enrollments.id NOT IN (SELECT enrollment_id FROM advisements)

      ORDER BY name, prof_name
    SQL
  },
  { name: "Bolsistas de Mestrado e Orientadores",
    description: "Lista os alunos de mestrado bolsistas e seus orientadores principais",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT students.name AS name,
             professors.name AS prof_name
      FROM enrollments
           INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
           INNER JOIN levels ON levels.id = enrollments.level_id
           INNER JOIN students ON students.id = enrollments.student_id
           LEFT OUTER JOIN advisements ON advisements.enrollment_id = enrollments.id
           INNER JOIN professors ON professors.id = advisements.professor_id
      WHERE enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND enrollment_statuses.name = "Regular"
      /* Apenas alunos de mestrado */
      AND levels.name = "Mestrado"
      /* Listas apenas Orientador Principal */
      AND advisements.main_advisor = 1
      /* Bolsista */
      AND enrollments.id IN (SELECT enrollment_id
                             FROM scholarship_durations
                             WHERE end_date > :data_consulta
                             AND cancel_date IS NULL)

      UNION

      /* Alunos bolsistas de mestrado ainda sem orientador */
      SELECT students.name AS name, "--" AS prof_name
      FROM enrollments
           INNER JOIN enrollment_statuses ON enrollment_statuses.id = enrollments.enrollment_status_id
           INNER JOIN levels ON levels.id = enrollments.level_id
           INNER JOIN students ON students.id = enrollments.student_id
      WHERE
      enrollments.id NOT IN (SELECT dismissals.enrollment_id from dismissals)
      AND enrollment_statuses.name = "Regular"
      /* Apenas alunos de mestrado */
      AND levels.name = "Mestrado"
      /* Bolsista */
      AND enrollments.id IN (SELECT enrollment_id
                             FROM scholarship_durations
                             WHERE end_date > :data_consulta
                             AND cancel_date IS NULL)
      /* Não está entre os que possuem orientador */
      AND enrollments.id NOT IN (SELECT enrollment_id FROM advisements)

      ORDER BY name, prof_name
    SQL
  },
  { name: "CHECK BOLSA: Alunos bolsistas com pelo menos 1 reprovação",
    description: "",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.email,
             enrollment_number,
             COUNT(*) AS num_reprovacoes
      FROM students s, enrollments e, class_enrollments ce, courses c,
           course_types ct, course_classes cc, enrollment_statuses es
      WHERE s.id = e.student_id
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND ce.enrollment_id = e.id
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation = "Reprovado"
        AND cc.year >= 2019
        /* Bolsista */
        AND e.id IN (SELECT enrollment_id
                     FROM scholarship_durations
                     WHERE end_date > :data_consulta
                     AND cancel_date IS NULL)
      GROUP BY s.name, e.enrollment_number
      HAVING num_reprovacoes >= 1
      ORDER BY s.name
    SQL
  },
  { name: "Alunos avulsos em determinado Ano/Semestre",
    description: "",
    params: [
      {
        name: "ano",
        value_type: "Integer",
        default_value: "2018"
      },
      {
        name: "semestre",
        value_type: "Integer",
        default_value: "2"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name, s.email,
             e.enrollment_number,
             cc.year,
             cc.semester,
             c.name AS disciplina,
             ce.grade,
             c.credits
      FROM students s, enrollments e, class_enrollments ce, courses c,
        course_types ct, course_classes cc, enrollment_statuses es
      WHERE s.id = e.student_id
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
        AND e.enrollment_status_id = es.id
        AND es.name = "Avulso"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation != "Incompleto"
        AND cc.year = :ano
        AND cc.semester = :semestre
      ORDER BY s.name
    SQL
  },
  { name: "Prorrogações concedidas",
    description: "Prorrogações concedidas em determinada data",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT students.name AS student,
             deferral_types.name AS type,
             deferrals.approval_date
      FROM deferrals
          INNER JOIN deferral_types ON deferrals.deferral_type_id = deferral_types.id
          INNER JOIN enrollments ON enrollments.id = deferrals.enrollment_id
          INNER JOIN students ON students.id = enrollments.student_id
      WHERE approval_date = :data_consulta
      ORDER BY deferral_types.name, students.name
    SQL
  },
  { name: "Consulta LOG",
    description: "Essa consulta serve de exemplo para consulta no log do sistema. Aqui ela pega ações de conclusão de etapa do aluno cujo enrollment_id é 879.",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT * FROM versions
      WHERE item_type = "Accomplishment"
      AND object LIKE "%%879%%";
    SQL
  },
  { name: "Conferência Inscrição em Disciplina",
    description: "Consulta usada numa notificação enviada a todos os alunos pedindo que confiram as disciplinas em que foram inscritos",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer",
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer",
      },
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name, s.email AS email,
             e.enrollment_number AS enrollment_number,
             c.name AS disciplina, cc.year, cc.semester
      FROM students s, enrollments e,`class_enrollments` ce,
        courses c, course_types ct, course_classes cc, enrollment_statuses es
      WHERE s.id = e.student_id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      /* apenas inscrições desse período */
      AND cc.year = :ano_semestre_atual
      AND cc.semester = :numero_semestre_atual
      AND ce.course_class_id = cc.id
      AND c.id=cc.course_id
      AND e.enrollment_status_id = es.id
      /* alunos regulares e avulsos */
      AND (es.name = "Regular" OR es.name = "Avulso")
      AND ce.enrollment_id = e.id
      AND ct.id = c.course_type_id
      AND c.id = cc.course_id
      AND cc.id = ce.course_class_id
      ORDER BY s.name
    SQL
  },
  { name: "ALUNOS ativos regulares para envio de boletim anexado",
    description: "Seleciona alunos ativos regulares na data escolhida. Feita para em notificação com boletim em anexo. Inclui uma coluna com o id de matrícula (AS enrollments_id) que é necessário para gerar o boletim",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [
      {
        title: "ALUNOS: Envio de boletim para ativos regulares [Agendamento sugerido: Semestral 0]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "0",
        individual: true,
        has_grades_report_pdf_attachment: true,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Boletim Escolar da Pós-Graduação",
        body_template: <<~LIQUID
          Prezado(a) {{ name }}

          Enviamos por este email, em anexo, seu Boletim Escolar da Pós-Graduação.

          Att, Coordenação
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT
        students.name AS name, students.email AS email,
        enrollments.id AS enrollments_id
      FROM
        students, enrollments, enrollment_statuses
      WHERE
        enrollments.student_id = students.id
        AND enrollments.enrollment_status_id = enrollment_statuses.id
        AND enrollment_statuses.name = "Regular"
        AND enrollments.admission_date < :data_consulta
        AND enrollments.id NOT IN (SELECT enrollment_id
                                   FROM dismissals
                                   WHERE date < :data_consulta)
      ORDER BY
        students.name
    SQL
  },
  { name: "Histórico de Jubilados com CR < 6",
    description: "Nomes de todos os alunos que foram jubilados pelo critério de CR < 6",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name,
             e.enrollment_number,
             cc.year,
             cc.semester,
             round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10)+0.05, 1) AS cr_periodo,
             SUM(credits)/4 AS num_disciplinas_semestre
      FROM students s, enrollments e, class_enrollments ce, courses c,
           course_types ct, course_classes cc, enrollment_statuses es
      WHERE s.id = e.student_id
        AND e.enrollment_status_id = es.id
        AND e.id IN (SELECT d.enrollment_id
                     FROM dismissals d, dismissal_reasons dr
                     WHERE d.dismissal_reason_id = dr.id
                     AND dr.name = "Rendimento")
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation !=  "Incompleto"
      GROUP BY s.name, e.enrollment_number, cc.year, cc.semester
      HAVING SUM(ce.grade * c.credits)/SUM(c.credits) < 59.5
      ORDER BY cc.year, cc.semester, e.enrollment_number
    SQL
  },
  { name: "Alunos em disciplinas",
    description: "Alunos que ainda não completaram 24 créditos cursados.",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS "Aluno",
             e.enrollment_number AS "Matrícula",
             CAST((24 - IFNULL(SUM(c.credits),0)) / 4 AS INT) AS "Disciplinas Pendentes"
      FROM students s
      INNER JOIN enrollments e ON s.id = e.student_id
      INNER JOIN enrollment_statuses es ON es.id = e.enrollment_status_id
      LEFT JOIN class_enrollments ce ON ce.enrollment_id = e.id
      LEFT JOIN course_classes cc ON cc.id = ce.course_class_id
      LEFT JOIN courses c ON c.id = cc.course_id
      LEFT JOIN course_types ct ON (ct.id = c.course_type_id
                            AND ct.has_score = 1 /* Disciplinas com nota */
                AND (ct.name <> "Estágio em Docência") /* Desconsidera Estágio de Docência */)
      WHERE e.id NOT IN (SELECT enrollment_id FROM dismissals) /* Somente ativos */
      AND es.name = "Regular" /* Somente regulares */
      GROUP BY s.name, e.enrollment_number
      HAVING IFNULL(SUM(c.credits),0) < 24
      ORDER BY s.name
    SQL
  },
  { name: "Turmas por semestre",
    description: "Lista o número de turmas que oferecemos a cada ano/semestre.",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT cc.year AS "Ano",
             cc.semester AS "Semestre",
             COUNT(cc.id) AS "Turmas"
      FROM course_classes cc, courses c, course_types ct
      WHERE c.id = cc.course_id
      AND ct.id = c.course_type_id
      AND ct.has_score = 1 /* Disciplinas com nota */
      AND ct.name <> "Estágio em Docência" /* Desconsidera */
      AND ct.name <> "Estudo Orientado" /* Desconsidera */
      AND cc.id IN (SELECT ce.course_class_id
                    FROM class_enrollments ce
                    GROUP BY ce.course_class_id
                    HAVING COUNT(ce.id) >= 3)
      AND LOWER(cc.name) NOT LIKE "%%aproveitamento%%"
      GROUP BY cc.year, cc.semester
      ORDER BY cc.year, cc.semester
    SQL
  },
  { name: "Alunos que pediram banca mas que não tem data de defesa ou não foram desligados",
    description: "Essa consulta foi feita para ver se tinha alguma inconsistência no Sapos.",
    params: [],
    notifications: [],
    sql: <<~SQL
      /* Data de defesa em branco */
      SELECT s.name as Nome,
             e.enrollment_number as Matrícula,
             a.conclusion_date as "data pedido banca",
             "sem data de defesa" as Problema
      FROM enrollments e, students s, accomplishments a, phases p
      WHERE s.id = e.student_id
      AND a.enrollment_id = e.id
      AND a.phase_id = p.id
      AND p.name = "Pedido de Banca" /* Etapa é pedido de banca */
      AND e.thesis_defense_date IS NULL

      UNION

      /* Não foram desligados */
      SELECT s.name as Nome,
             e.enrollment_number as Matrícula,
             a.conclusion_date as "data pedido banca",
             "não foi desligado" as Problema
      FROM enrollments e, students s, accomplishments a, phases p
      WHERE s.id = e.student_id
      AND a.enrollment_id = e.id
      AND a.phase_id = p.id
      AND p.name = "Pedido de Banca" /* Etapa é pedido de banca */
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
    SQL
  },
  { name: "Alunos que se inscreveram em Estudo Orientado",
    description: "Usar para checar se todos entregaram o plano de estudo.",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer",
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer",
      },
    ],
    notifications: [
      { title: "SEC: Alunos que devem entregar o plano de estudo orientado [Agendamento sugerido: Semestral 19d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "19",
        individual: false,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{% emails Secretaria %}",
        subject_template: "Alunos que devem entregar o plano de estudo orientado",
        body_template: <<~LIQUID
          Secretaria,

          Informamos que os seguintes alunos devem entregar o plano de estudo orientado

          {% for record in records %}
              - {{ record.name }} ({{ record.enrollment_number }})
          {% endfor %}

          Todos esses alunos acabaram de ser notificados que devem fazer essa entrega.
        LIQUID
      },
      { title: "ALUNOS: Alunos que devem entregar o plano de estudo orientado [Agendamento sugerido: Semestral 19d]",
        frequency: "Manual",
        notification_offset: "0",
        query_offset: "19",
        individual: true,
        has_grades_report_pdf_attachment: false,
        template_type: "Liquid",
        to_template: "{{ email }}",
        subject_template: "Prazo para a entrega do plano de estudo orientado",
        body_template: <<~LIQUID
          {{ name }}

          Lembramos que você tem até 30 dias a partir do início das aulas para entregar o plano de estudo orientado.

          Para maiores informações, consulte as regras disponíveis em nosso site.

          Caso você já tenha realizado a entrega, favor desconsiderar essa mensagem.
        LIQUID
      }
    ],
    sql: <<~SQL
      SELECT s.name, e.enrollment_number, s.email
      FROM students s, enrollments e, class_enrollments ce, course_classes cc,
           courses c, course_types ct, enrollment_statuses es
      WHERE s.id = e.student_id
      AND e.id = ce.enrollment_id
      AND e.enrollment_status_id = es.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND es.name = "Regular" /* Aluno Regular */
      AND ce.course_class_id = cc.id
      AND cc.course_id = c.id
      AND c.course_type_id = ct.id
      AND cc.year = :ano_semestre_atual
      AND cc.semester = :numero_semestre_atual
      AND ct.name = "Estudo Orientado"
      AND (ce.obs IS NULL OR ce.obs NOT LIKE '%PROPOSTA OK%') /* e não tiver "PROPOSTA OK" na inscrição */
      ORDER BY s.name
    SQL
  },
  { name: "Data dos pedidos de inscrição em uma turma",
    description: "",
    params: [
      {
        name: "id_turma",
        value_type: "Integer",
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name as "Nome",
             s.email as "Email",
             cer.action as "Ação",
             cer.status as "Status",
             cer.created_at as "Data do pedido"
      FROM class_enrollment_requests cer, enrollment_requests er,
           enrollments e, students s
      WHERE cer.course_class_id = :id_turma
        AND cer.enrollment_request_id = er.id
        AND er.enrollment_id = e.id
        AND e.student_id = s.id
      ORDER BY s.name
    SQL
  },
  { name: "Data das inscrições em uma turma",
    description: "",
    params: [
      {
        name: "id_turma",
        value_type: "Integer",
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name as "Nome",
             s.email as "Email",
             ce.created_at as "Data do pedido"
      FROM class_enrollments ce, enrollments e, students s
      WHERE ce.course_class_id = :id_turma
        AND ce.enrollment_id = e.id
        AND e.student_id = s.id
      ORDER BY s.name
    SQL
  },
  { name: "Número de alunos por professor credenciado e nível",
    description: "Lista, para cada professor credenciado, o número de alunos que ele orienta em cada nível.",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT p.name as "professor",
             l.name as "nível",
             COUNT(DISTINCT(e.id)) as "orientandos"
      FROM advisement_authorizations aa, professors p, advisements a, levels l, enrollments e
      WHERE aa.professor_id = p.id
      AND p.id = a.professor_id
      AND a.enrollment_id = e.id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
      AND e.level_id = l.id
      GROUP BY p.name, l.name
    SQL
  },
  { name: "Contagem de inscrições por aluno",
    description: "Lista todos os alunos regulares que estão ativos e indica em quantas disciplinas eles fizeram pedidos de inscrição ou tiveram inscrição efetivada.",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer",
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer",
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT s.name as "nome",
             e.enrollment_number as "matrícula",
             COUNT(cer_sol.id) as "inscrições solicitadas",
             COUNT(cer_val.id) as "inscrições válidas",
             COUNT(ce.id) as "inscrições efetivadas"
      FROM students s
      INNER JOIN enrollments e ON s.id = e.student_id
      INNER JOIN enrollment_statuses es ON es.id = e.enrollment_status_id
      LEFT JOIN (enrollment_requests er_sol, class_enrollment_requests cer_sol, course_classes cc_sol)
          ON (e.id = er_sol.enrollment_id AND er_sol.id = cer_sol.enrollment_request_id AND cer_sol.course_class_id = cc_sol.id AND cer_sol.status = "Solicitada" AND cc_sol.year = :ano_semestre_atual AND cc_sol.semester = :numero_semestre_atual)
      LEFT JOIN (enrollment_requests er_val, class_enrollment_requests cer_val, course_classes cc_val)
          ON (e.id = er_val.enrollment_id AND er_val.id = cer_val.enrollment_request_id AND cer_val.course_class_id = cc_val.id AND cer_val.status = "Válida" AND cc_val.year = :ano_semestre_atual AND cc_val.semester = :numero_semestre_atual)
      LEFT JOIN (class_enrollments ce, course_classes cc)
          ON (e.id = ce.enrollment_id AND ce.course_class_id = cc.id AND cc.year = :ano_semestre_atual AND cc.semester = :numero_semestre_atual)
      WHERE es.name = "Regular" /* Aluno regular */
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals)  /* Aluno ativo */
      GROUP BY e.id
      ORDER BY s.name
    SQL
  },
  { name: "CHECK INSCRIÇÃO - Avulsos cursando mais de 4 disciplinas em todas as suas matrículas ativas",
    description: "Máx 4 disc. Consideramos todas as matrículas avulsas ativas do mesmo aluno.",
    params: [],
    notifications: [],
    sql: <<~SQL
      SELECT s.name AS name,
             s.email AS email,
             COUNT(*) as "num_disciplinas"
      FROM students s, enrollments e, enrollment_statuses es, class_enrollments ce
      WHERE s.id = e.student_id
      AND e.enrollment_status_id = es.id
      AND e.id = ce.enrollment_id
      AND e.id NOT IN (SELECT enrollment_id FROM dismissals) /* Aluno ativo */
      AND es.name = "Avulso" /* Aluno avulso */
      GROUP BY s.id
      HAVING COUNT(*) > 4
      ORDER BY s.name
    SQL
  },
  { name: "Número de alunos ativos por nível e sexo",
    description: "",
    params: [
      {
        name: "data_consulta",
        value_type: "Date"
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT count(*) AS num_alunos,
             levels.name AS nivel, students.sex AS sexo
      FROM enrollments, levels, students, enrollment_statuses
      WHERE enrollments.id NOT IN (SELECT enrollment_id
                                   FROM dismissals
                                   WHERE date < :data_consulta)
      AND admission_date < :data_consulta
      AND enrollments.enrollment_status_id = enrollment_statuses.id
      AND enrollments.level_id = levels.id
      AND enrollments.student_id = students.id
      AND enrollment_statuses.name = "Regular"
      GROUP BY level_id, sex
    SQL
  },
  { name: "Taxa de sucesso por sexo",
    description: "Consulta retorna número total de matriculados num determinado ano semestre por sexo, e também o número de cada tipo de desligamento, sempre contando por data de admissão. Copiar o resultado numa tabela excel para manipular os números.",
    params: [],
    notifications: [],
    sql: <<~SQL
      /* Numero de alunos matriculados em cada nivel por semestre */
      SELECT l.name AS NIVEL,
             s.sex AS SEXO,
             e.admission_date AS DATA_MATRICULA,
             "Total Matriculados" AS STATUS,
             COUNT(*) AS NUM_ALUNOS
      FROM enrollments e, levels l, students s, enrollment_statuses es
      WHERE l.id = e.level_id
      AND e.enrollment_status_id = es.id
      AND es.name = "Regular"
      AND e.admission_date > "2010-01-01"
      AND e.student_id = s.id
      GROUP BY l.name, s.sex, e.admission_date

      UNION

      /* Numero de desligamentos, por motivo, de alunos matriculados num determinado ano semestre */
      SELECT l.name AS NIVEL,
             s.sex AS SEXO,
             e.admission_date AS DATA_MATRICULA,
             dr.name AS STATUS,
             COUNT(*) AS NUM_ALUNOS
      FROM enrollments e, dismissals d, dismissal_reasons dr, levels l,
           students s, enrollment_statuses es
      WHERE e.id = d.enrollment_id
      AND d.dismissal_reason_id = dr.id
      AND l.id = e.level_id
      AND e.enrollment_status_id = es.id
      AND es.name = "Regular"
      AND e.admission_date > "2010-01-01"
      AND e.student_id = s.id
      GROUP BY l.name, s.sex, e.admission_date, dr.name
    SQL
  },
  { name: "CHEFIA: Alunos regulares inscritos em turmas",
    description: "Lista o número de inscritos em todas as turmas de um determinado ano/semestre, só considerando inscrições no estado \"incompleto\", evitando assim que aproveitamentos de disciplinas já cursadas como avulso sejam contabilizados.",
    params: [
      {
        name: "ano_semestre_atual",
        value_type: "Integer",
      },
      {
        name: "numero_semestre_atual",
        value_type: "Integer",
      },
    ],
    notifications: [],
    sql: <<~SQL
      SELECT cc.name AS "Disciplina",
             p.name AS "Professor",
             COUNT(*) AS "Total de alunos",
             SUM(case when es.name = "Regular" then 1 else 0 end) AS "Alunos regulares",
             SUM(case when es.name = "Avulso" then 1 else 0 end) AS "Alunos avulsos"
      FROM course_classes cc, professors p, class_enrollments ce, enrollments e,
           enrollment_statuses es, courses c, course_types ct
      WHERE cc.year = :ano_semestre_atual
      AND cc.semester = :numero_semestre_atual
      AND cc.professor_id = p.id
      AND cc.course_id = c.id
      AND c.course_type_id = ct.id
      AND e.enrollment_status_id = es.id
      AND (
        ct.name = "Tópicos Avançados"
        OR ct.name = "Obrigatória de Curso"
        OR ct.name = "Obrigatória de Linha de Pesquisa"
        OR ct.name = "Optativa"
      )
      AND cc.id = ce.course_class_id
      AND ce.situation = "Incompleto"
      AND ce.enrollment_id = e.id
      GROUP BY cc.name
      ORDER BY cc.name
    SQL
  },
]

unless is_sqlite
  queries.concat([
    { name: "CHECK INSCRIÇÃO - Alunos que se inscreveram em pesquisa de dissertação ou tese mas não cumpriram os requisitos do curso",
      description: "Requisitos analisados: seminários, créditos, básica do curso e obrigatória de linha de pesquisa.",
      params: [],
      notifications: [
        { title: "ALUNOS: inscrição inapropriada em pesquisa de tese/dissertação",
          frequency: "Manual",
          notification_offset: "0",
          query_offset: "0",
          individual: true,
          has_grades_report_pdf_attachment: false,
          template_type: "Liquid",
          to_template: "{{ email }}",
          subject_template: "Inscrição inapropriada em pesquisa de tese/dissertação",
          body_template: <<~LIQUID
            {{ name }}

            Você se inscreveu em pesquisa de tese/dissertação, porém não cumpriu ainda todos os requisitos para poder fazer inscrição nesse tipo de disciplina. O requisito "{{ requisito }}" ainda está pendente.

            Por favor, remova a inscrição em pesquisa de tese/dissertação e faça a inscrição nas disciplinas que atendam ao requisito que está pendente.

            Caso perceba alguma inconsistência nessa mensagem, por favor, entre em contato com a secretaria do curso imediatamente.
          LIQUID
        }
      ],
      sql: <<~SQL
        SELECT DISTINCT s.name AS "nome",
            s.email AS "email",
            e.enrollment_number AS "matrícula",
            e.admission_date AS "entrada",
            r.requirement AS "requisito"
        FROM students s, enrollments e, class_enrollments ce,
            course_classes cc, courses c, enrollment_statuses es, course_types ct, (

        /* aluno que não se inscreveu em seminários */
        SELECT e2.id AS "enrollment_id",
              "seminários" AS "requirement"
        FROM enrollments e2
        WHERE e2.id NOT IN (SELECT ce3.enrollment_id
                FROM class_enrollments ce3, course_classes cc3, courses c3,
                    course_types ct3
                WHERE ce3.course_class_id = cc3.id
                  AND cc3.course_id = c3.id
                  AND c3.course_type_id = ct3.id
                  AND ct3.name = "Seminário")

        UNION

        /* aluno de doutorado ou aluno de mestrado (currículo novo) que não completou os 24 créditos  */
        SELECT e2.id AS "enrollment_id",
              "24 creditos (EDI e EDII não contam crédito)" AS "requirement"
        FROM enrollments e2, class_enrollments ce2, course_classes cc2,
            courses c2, levels l2
        WHERE e2.id = ce2.enrollment_id
        AND ce2.course_class_id = cc2.id
        AND cc2.course_id = c2.id
        AND e2.level_id = l2.id
        /* aluno de doutorado ou aluno de mestrado que entrou a partir de 2021 ou que optou pelo novo regimento */
        AND (
          l2.name = "Doutorado"
          OR (
            l2.name = "Mestrado"
            AND (
              YEAR(e2.admission_date) >= 2021
              OR (e2.obs IS NOT NULL AND e2.obs LIKE "%%regimento%%16/12/2020%%")
            )
          )
        )
        AND ce2.situation = "Aprovado" /* disciplinas que o aluno foi aprovado */
        AND c2.course_type_id NOT IN (SELECT course_types.id FROM course_types
                                      WHERE course_types.name = "Estágio em Docência") /* estágio de docência não conta */
        GROUP BY e2.id
        HAVING SUM(c2.credits) < 24

        UNION

        /* aluno de mestrado (currículo antigo) que não completou os 32 créditos  */
        SELECT e2.id AS "enrollment_id",
              "32 creditos (EDI e EDII não contam crédito)" AS "requirement"
        FROM enrollments e2, class_enrollments ce2, course_classes cc2,
            courses c2, levels l2
        WHERE e2.id = ce2.enrollment_id
        AND ce2.course_class_id = cc2.id
        AND cc2.course_id = c2.id
        AND e2.level_id = l2.id
        /* aluno de mestrado que entrou antes de 2021 e que não optou pelo novo regimento */
        AND l2.name = "Mestrado"
        AND YEAR(e2.admission_date) < 2021
        AND (e2.obs IS NULL OR e2.obs NOT LIKE "%%regimento%%16/12/2020%%")
        AND ce2.situation = "Aprovado" /* disciplinas que o aluno foi aprovado */
        AND c2.course_type_id NOT IN (SELECT course_types.id FROM course_types
                                      WHERE course_types.name = "Estágio em Docência") /* estágio de docência não conta */
        GROUP BY e2.id
        HAVING SUM(c2.credits) < 32

        UNION

        /* aluno de doutorado (currículo antigo) que não teve duas básicas com nota > 7 */
        SELECT e2.id AS "enrollment_id",
              "duas básicas > 7 (curriculo antigo)" AS "requirement"
        FROM enrollments e2, levels l2
        WHERE e2.student_id NOT IN (SELECT e3.student_id
                                    FROM enrollments e3, class_enrollments ce3,
                                        course_classes cc3, courses c3, course_types ct3
                                    WHERE e3.id = ce3.enrollment_id
                                    AND ce3.course_class_id = cc3.id
                                    AND cc3.course_id = c3.id
                                    AND c3.course_type_id = ct3.id
                                    AND ct3.name = "Obrigatória de Curso" /* básica do curso */
                                    AND ce3.situation =  "Aprovado" /* disciplinas que o aluno foi aprovado */
                                    AND ce3.grade >= 70 /* nota > 7 */
                                    GROUP BY e3.student_id
                                    HAVING COUNT(*) >= 2)
        /* aluno de doutorado matriculado antes de 2021 e não optou pelo novo regimento */
        AND e2.level_id = l2.id
        AND l2.name = "Doutorado"
        AND YEAR(e2.admission_date) < 2021
        AND (e2.obs IS NULL OR e2.obs NOT LIKE "%%regimento%%16/12/2020%%")
        AND (e2.obs IS NULL OR (e2.obs NOT LIKE "%%BASICAS > 7 OK%%" AND e2.obs NOT LIKE "%%BASICAS OK%%")) /* não cursou externamente as básicas */

        UNION

        /* aluno de mestrado (currículo antigo) ou aluno de doutorado (currículo novo) que não teve aprovação em duas básicas */
        SELECT e2.id AS "enrollment_id",
              "duas básicas" AS "requirement"
        FROM enrollments e2, levels l2
        WHERE e2.student_id NOT IN (SELECT e3.student_id
                                    FROM enrollments e3, class_enrollments ce3,
                                        course_classes cc3, courses c3, course_types ct3
                                    WHERE e3.id = ce3.enrollment_id
                                    AND ce3.course_class_id = cc3.id
                                    AND cc3.course_id = c3.id
                                    AND c3.course_type_id = ct3.id
                                    AND ct3.name = "Obrigatória de Curso" /* básica do curso */
                                    AND ce3.situation =  "Aprovado" /* disciplinas que o aluno foi aprovado */
                                    GROUP BY e3.student_id
                                    HAVING COUNT(*) >= 2)
        /* aluno de doutorado matriculado depois de 2021 ou optou pelo novo regimento
        ou aluno de mestrado matriculado antes de 2021 e não optou pelo novo regimento */
        AND e2.level_id = l2.id
        AND (
          (
            l2.name = "Doutorado"
            AND (
              YEAR(e2.admission_date) >= 2021
              OR (e2.obs IS NOT NULL AND e2.obs LIKE "%%regimento%%16/12/2020%%")
            )
          )
          OR (
            l2.name = "Mestrado"
            AND YEAR(e2.admission_date) < 2021
            AND (e2.obs IS NULL OR e2.obs NOT LIKE "%%regimento%%16/12/2020%%")
          )
        )
        AND (
          e2.obs IS NULL
          OR (e2.obs NOT LIKE "%%BASICAS > 7 OK%%" AND e2.obs NOT LIKE "%%BASICAS OK%%")
        ) /* não cursou externamente as básicas */

        UNION

        /* aluno de mestrado (currículo novo) que não teve aprovação em uma básica */
        SELECT e2.id AS "enrollment_id",
              "uma básica" AS "requirement"
        FROM enrollments e2, levels l2
        WHERE e2.id NOT IN (SELECT ce3.enrollment_id
                            FROM class_enrollments ce3, course_classes cc3,
                                courses c3, course_types ct3
                            WHERE ce3.course_class_id = cc3.id
                            AND cc3.course_id = c3.id
                            AND c3.course_type_id = ct3.id
                            AND ct3.name = "Obrigatória de Curso" /* básica do curso */
                            AND ce3.situation =  "Aprovado" /* disciplinas que o aluno foi aprovado */
                            GROUP BY ce3.enrollment_id
                            HAVING COUNT(*) >= 1)
        /* aluno de mestrado matriculado depois de 2021 ou que optou pelo novo regimento */
        AND e2.level_id = l2.id
        AND l2.name = "Mestrado"
        AND (
          YEAR(e2.admission_date) >= 2021
          OR (e2.obs IS NOT NULL AND e2.obs LIKE "%%regimento%%16/12/2020%%")
        )
        AND (e2.obs IS NULL OR e2.obs NOT LIKE "%%BASICAS OK%%") /* não cursou externamente as básicas */

        UNION

        /* aluno de mestrado que não teve aprovação em uma obrigatória de linha de pesquisa */
        SELECT e2.id AS "enrollment_id",
              "uma obrigatória de linha de pesquisa" AS "requirement"
        FROM enrollments e2, levels l2
        WHERE e2.id NOT IN (SELECT ce3.enrollment_id
                            FROM class_enrollments ce3, course_classes cc3,
                                courses c3, course_types ct3
                            WHERE ce3.course_class_id = cc3.id
                            AND cc3.course_id = c3.id
                            AND c3.course_type_id = ct3.id
                            AND ct3.name = "Obrigatória de Linha de Pesquisa" /* obrigatória de linha de pesquisa */
                            AND ce3.situation =  "Aprovado" /* disciplinas que o aluno foi aprovado */
                            GROUP BY ce3.enrollment_id
                            HAVING COUNT(*) >= 1)
        AND e2.level_id = l2.id
        AND l2.name = "Mestrado") r /* aluno de mestrado */

        WHERE s.id = e.student_id
        AND e.id = ce.enrollment_id
        AND ce.course_class_id = cc.id
        AND cc.course_id = c.id
        AND e.id = r.enrollment_id
        AND e.enrollment_status_id = es.id
        AND c.course_type_id = ct.id
        AND e.id NOT IN (SELECT d.enrollment_id FROM dismissals d) /* Aluno ativo */
        AND es.name = "Regular" /* Aluno regular */
        AND ct.name = "Pesquisa de Dissertação e Tese" /* Já se inscreveu em pesquisa de tese ou dissertação */
        ORDER BY nome
      SQL
    },
    { name: "CHECK JUBILAMENTO",
      description: "Lista alunos que precisam ser jubilados por terem CR < 6, ou CR < 7 em dois períodos consecutivos, ou 2 reprovações ou mais ",
      params: [
        {
          name: "ano_semestre_atual",
          value_type: "Integer",
        },
        {
          name: "numero_semestre_atual",
          value_type: "Integer",
        },
        {
          name: "ano_ultimo_semestre",
          value_type: "Integer",
        },
        {
          name: "numero_ultimo_semestre",
          value_type: "Integer",
        },
      ],
      notifications: [],
      sql: <<~SQL
        SELECT s.name, s.email,
               e.enrollment_number,
               cc.year,
               cc.semester,
               round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 1) AS cr_periodo,
               "CR < 6" AS motivo
        FROM students s, enrollments e, class_enrollments ce, courses c,
             course_types ct, course_classes cc, enrollment_statuses es
        WHERE s.id = e.student_id
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation != "Incompleto"
        AND ce.grade_not_count_in_gpr = False
        GROUP BY s.name, e.enrollment_number, cc.year, cc.semester
        HAVING SUM(ce.grade * c.credits)/SUM(c.credits) < 59.5
          AND COUNT(ce.id) > 1

        UNION

        SELECT s.name, s.email,
               e.enrollment_number,
               cc.year,
               cc.semester,
               "--" AS cr_periodo,
               "2 reprovações" AS motivo
        FROM students s, enrollments e, class_enrollments ce,
             courses c, course_classes cc, enrollment_statuses es
        WHERE s.id = e.student_id
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND ce.enrollment_id = e.id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation = "Reprovado"
        GROUP BY s.name, e.enrollment_number
        HAVING COUNT(*) >= 2

        UNION

        SELECT s.name, s.email,
               enrollment_number,
               cc.year,
               cc.semester,
               round(((SUM(ce.grade * c.credits)/SUM(c.credits))/10), 1) AS cr_periodo,
               "CR < 7 em dois períodos consecutivos" AS motivo
        FROM students s, enrollments e, class_enrollments ce,
             courses c, course_types ct, course_classes cc, enrollment_statuses es
        WHERE s.id = e.student_id
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals)
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular"
        AND ce.enrollment_id = e.id
        AND ct.has_score = 1
        AND ct.id = c.course_type_id
        AND c.id = cc.course_id
        AND cc.id = ce.course_class_id
        AND ce.situation != "Incompleto"
        AND ce.grade_not_count_in_gpr = False
        AND cc.year = :ano_semestre_atual
        AND cc.semester = :numero_semestre_atual
        /* e também teve CR menor do que 7 no semestre anterior */
        AND e.id IN (SELECT e.id
                     FROM enrollments e, class_enrollments ce, courses c,
                     course_types ct, course_classes cc, enrollment_statuses es
                     WHERE e.id NOT IN (SELECT enrollment_id FROM dismissals)
                     AND e.enrollment_status_id = es.id
                     AND es.name = "Regular"
                     AND ce.enrollment_id = e.id
                     AND ct.has_score = 1
                     AND ct.id = c.course_type_id
                     AND c.id = cc.course_id
                     AND cc.id = ce.course_class_id
                     AND ce.situation != "Incompleto"
                     AND ce.grade_not_count_in_gpr = False
                     AND cc.year = :ano_ultimo_semestre
                     AND cc.semester = :numero_ultimo_semestre
                     GROUP BY e.id
                     HAVING SUM(ce.grade * c.credits)/SUM(c.credits) < 69.5)
        GROUP BY s.name, e.enrollment_number, cc.year, cc.semester
        HAVING SUM(ce.grade * c.credits)/SUM(c.credits) < 69.5
        ORDER BY name
      SQL
    },
    { name: "Tempo médio de titulação por período",
      description: "Quanto tempo os alunos que entraram em um determinado período demoraram para defender",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT level_id AS NIVEL, admission_date AS DATA_ADMISSÃO, AVG( TIMESTAMPDIFF(
        MONTH , e.admission_date, d.date ) +1 ) AS TEMPO_TITULAÇÃO
        FROM enrollments e, enrollment_statuses es, dismissals d, dismissal_reasons dr
        WHERE e.id = d.enrollment_id
        AND d.dismissal_reason_id = dr.id
        AND e.enrollment_status_id = es.id
        AND dr.name = "Titulação"
        AND es.name = "Regular"
        GROUP BY admission_date, level_id
        ORDER BY admission_date
      SQL
    },
    { name: "Tempo médio de titulação por ano",
      description: "Quanto tempo os alunos que defenderam em um determinado ano demoraram para defender",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT level_id AS NIVEL, YEAR( d.date ) , AVG( TIMESTAMPDIFF(
        MONTH , e.admission_date, d.date ) +1 ) AS TEMPO_TITULAÇÃO, COUNT(*) AS NUM_DEFESAS
        FROM enrollments e, enrollment_statuses es, dismissals d, dismissal_reasons dr
        WHERE e.id = d.enrollment_id
        AND d.dismissal_reason_id = dr.id
        AND e.enrollment_status_id = es.id
        AND dr.name = "Titulação"
        AND es.name = "Regular"
        GROUP BY YEAR( d.date ) , level_id
      SQL
    },
    { name: "Alunos titulados em um determinado ano",
      description: "",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT s.name AS NOME, l.name AS NIVEL, YEAR( d.date ) AS YEAR, TIMESTAMPDIFF(
        MONTH , e.admission_date, d.date ) +1  AS TEMPO_TITULAÇÃO
        FROM enrollments e, enrollment_statuses es,
             dismissals d, dismissal_reasons dr, students s, levels l
        WHERE e.id = d.enrollment_id
        AND e.enrollment_status_id = es.id
        AND d.dismissal_reason_id = dr.id
        AND es.name = "Regular"
        AND dr.name = "Titulação"
        AND e.student_id = s.id
        AND e.level_id = l.id
        ORDER BY YEAR, NIVEL, NOME
      SQL
    },
    { name: "Tempo médio de titulação por ano e por sexo",
      description: "Quanto tempo os alunos que defenderam em um determinado ano demoraram para defender, separado por sexo.",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT level_id AS NIVEL, s.sex AS SEXO, YEAR( d.date ) , AVG( TIMESTAMPDIFF(
        MONTH , e.admission_date, d.date ) +1 ) AS TEMPO_TITULAÇÃO, COUNT(*) AS NUM_DEFESAS
        FROM enrollments e, enrollment_statuses es, dismissals d,
             dismissal_reasons dr, students s
        WHERE e.id = d.enrollment_id
        AND d.dismissal_reason_id = dr.id
        AND e.enrollment_status_id = es.id
        AND dr.name = "Titulação"
        AND es.name = "Regular"
        AND s.id = e.student_id
        GROUP BY YEAR( d.date ) , level_id, s.sex
      SQL
    },
    { name: "Número de defesas por ano",
      description: "",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT level_id AS NIVEL, YEAR( d.date ), COUNT(*) AS NumDefesas
        FROM enrollments e, enrollment_statuses es, dismissals d, dismissal_reasons dr
        WHERE e.id = d.enrollment_id
        AND e.enrollment_status_id = es.id
        AND d.dismissal_reason_id = dr.id
        AND es.name = "Regular"
        AND dr.name = "Titulação"
        GROUP BY YEAR( d.date ) , level_id
      SQL
    },
    { name: "Alunos estrangeiros ativos em determinado ano",
      description: "",
      params: [
        {
          name: "ano",
          value_type: "Integer"
        },
      ],
      notifications: [],
      sql: <<~SQL
        SELECT s.name AS NOME, l.name AS NIVEL, c.name AS PAIS, e.admission_date AS DATA_MATRICULA
        FROM enrollments e, levels l, students s, countries c, states, enrollment_statuses es
        WHERE l.id = e.level_id
        AND s.id = e.student_id
        AND s.birth_state_id = states.id
        AND states.country_id = c.id
        AND e.enrollment_status_id = es.id
          /* Aluno Regular */
        AND es.name = "Regular"

        /* Aluno estava ativo num determinado ano */
        /* Não foi desligado antes desse ano */
        AND e.id NOT IN (SELECT enrollment_id FROM dismissals WHERE YEAR(date) <= :ano)
        /* Não se matriculou após esse ano */
        AND NOT (YEAR(e.admission_date) > :ano)

        /* É estrangeiro */
        AND s.birth_state_id NOT IN (SELECT s2.id
                                    FROM states s2, countries c2
                                    WHERE s2.country_id = c2.id
                                    AND c2.name = "Brasil")
        ORDER BY s.name
      SQL
    },
    { name: "Alunos ativos em um determinado ano, com o respectivo status",
      description: "Lista todos os alunos que tiveram matricula ativa em algum momento de um determinado ano. Caso o aluno tenha sido desligado no ano, indica a razão e a data de desligamento. Informação relevante para a coleta CAPES.",
      params: [
        {
          name: "ano",
          value_type: "Integer",
        },
      ],
      notifications: [],
      sql: <<~SQL
        /* Alunos desligados no ano */
        SELECT s.name as "nome",
              e.enrollment_number as "matrícula",
              l.name as "nível",
              dr.description as "situação",
              d.date as "data de desligamento"
        FROM students s, enrollments e, enrollment_statuses es, levels l,
            dismissals d, dismissal_reasons dr
        WHERE s.id = e.student_id
        AND e.id = d.enrollment_id
        AND e.level_id = l.id
        AND e.id = d.enrollment_id
        AND d.dismissal_reason_id = dr.id
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular" /* Alunos regulares */
        AND YEAR(d.date) = :ano

        UNION

        /* Alunos ativos no ano */
        SELECT s.name as "nome",
              e.enrollment_number as "matrícula",
              l.name as "nível",
              "Aluno ativo" as "situação",
              "N/A" as "data de desligamento"
        FROM students s, enrollments e, enrollment_statuses es, levels l
        WHERE s.id = e.student_id
        AND e.level_id = l.id
        AND e.enrollment_status_id = es.id
        AND es.name = "Regular" /* Alunos regulares */
        AND YEAR(e.admission_date) <= :ano /* não entrou depois do ano informado */
        AND e.id NOT IN (SELECT d.enrollment_id
                        FROM dismissals d
                        WHERE YEAR(d.date) <= :ano) /* não saiu antes ou no ano informado */
        ORDER BY nome
      SQL
    },
    { name: "Número de defesas de mulheres por ano",
      description: "",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT level_id AS NIVEL, YEAR( d.date ) AS ANO, COUNT(*) AS NUMDEFESAS
        FROM enrollments e, enrollment_statuses es,
            dismissals d, dismissal_reasons dr, students s
        WHERE e.id = d.enrollment_id
        AND s.id = e.student_id
        AND d.dismissal_reason_id = dr.id
        AND e.enrollment_status_id = es.id
        AND s.sex = 'F'
        AND dr.name = "Titulação"
        AND es.name = "Regular"
        GROUP BY YEAR( d.date ) , level_id
      SQL
    },
    { name: "Alunos que não entregaram documentos obrigatórios",
      description: "Listagem de alunos que não entregaram documentos obrigatórios (como diploma, etc) após 60 dias da data da matrícula.",
      params: [
        {
          name: "data_consulta",
          value_type: "Date"
        }
      ],
      notifications: [
        { title: "ALUNOS: documentação pendente [Agendamento sugerido: Semestral 0]",
          frequency: "Manual",
          notification_offset: "0",
          query_offset: "0",
          individual: true,
          has_grades_report_pdf_attachment: false,
          template_type: "Liquid",
          to_template: "{{ email }}",
          subject_template: "Documentação pendente",
          body_template: <<~LIQUID
            {{ name }}

            Lembramos que, de acordo com o termo de compromisso assinado na matrícula, você deve entregar na secretaria uma cópia do seu diploma de graduação e, para alunos de doutorado, uma cópia do seu diploma de mestrado.

            Vale notar que o pedido de banca de defesa de dissertação ou exame de qualificação só será aceito quando essa documentação for entregue.

            Caso você já tenha enviado a documentação, por favor, entre em contato com a secretaria.
          LIQUID
        },
        { title: "SEC: alunos com documentação pendente [Agendamento sugerido: Semestral 0]",
          frequency: "Manual",
          notification_offset: "0",
          query_offset: "0",
          individual: false,
          has_grades_report_pdf_attachment: false,
          template_type: "Liquid",
          to_template: "{% emails Secretaria %}",
          subject_template: "Alunos com documentação pendente",
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
      ],
      sql: <<~SQL
        SELECT s.name, s.email, e.enrollment_number
        FROM enrollments e, students s
        WHERE s.id = e.student_id
        AND e.id NOT IN (SELECT d.enrollment_id from dismissals d)
        /* A consulta considera que a matrícula foi feita
        um mês antes do início das aulas, por isso aqui está 30 ao invés de 60 */
        AND (DATEDIFF(:data_consulta, e.admission_date) > 30)
        AND (e.obs LIKE '%DOC PENDENTE%')
      SQL
    },
    { name: "Alunos que não entregaram a versão final da dissertação/tese",
      description: "Alunos que não entregaram a versão final da dissertação/tese após 30 dias da defesa ou 90 no caso de aprovação condicional",
      params: [
        {
          name: "data_consulta",
          value_type: "Date"
        }
      ],
      notifications: [
        { title: "SEC: Alunos que não entregaram versão final [Agendamento sugerido: Semanal 0]",
          frequency: "Manual",
          notification_offset: "0",
          query_offset: "0",
          individual: false,
          has_grades_report_pdf_attachment: false,
          template_type: "Liquid",
          to_template: "{% emails Secretaria %}",
          subject_template: "[SAPOS] Alunos que não entregaram a versão final",
          body_template: <<~LIQUID
            Secretaria,

            Informamos que o prazo para entrega da versão final dos seguintes alunos se esgotou. Tanto os alunos quanto os orientadores foram alertados sobre o ocorrido.

            {% for record in records %}
                - {{ record.student_name }} ({{ record.enrollment_number }}, defesa em {{ record.thesis_defense_date | localize: 'defaultdate' }})
            {% endfor %}

            Caso algum aluno dessa lista já tenha entregue a versão final, colocar "VF OK" na observação da realização da etapa Pedido de Banca do referido aluno.
          LIQUID
        },
        { title: "ALUNOS: Prazo vencido para entrega da versão final da dissertação/tese [Agendamento sugerido: Semanal 0]",
          frequency: "Manual",
          notification_offset: "0",
          query_offset: "0",
          individual: true,
          has_grades_report_pdf_attachment: false,
          template_type: "Liquid",
          to_template: "{{ student_email }}",
          subject_template: "Prazo de entrega de versão final vencido",
          body_template: <<~LIQUID
            {{ student_name }}

            Lembramos que venceu o prazo para entregar a versão final da sua tese/dissertação, defendida em {{ thesis_defense_date | localize: 'defaultdate' }}.

            Entre em contato com a secretaria imediatamente, apresentando uma carta em pdf com a justificativa do atraso, uma solicitação de prazo adicional de, no máximo, 15 dias, e a ciência de que será jubilado e perderá o título caso não cumpra o prazo solicitado. Essa carta deve ser assinada tanto pelo aluno quanto pelo orientador.


            Caso você já tenha entregue a versão final ou já tenha entrado em contato com a secretaria, favor desconsiderar essa mensagem.
          LIQUID
        }
      ],
      sql: <<~SQL
        SELECT s.name AS student_name, s.email AS student_email, e.enrollment_number, e.thesis_defense_date
        FROM enrollments e, students s, accomplishments a, phases p
        WHERE s.id = e.student_id
        AND a.enrollment_id = e.id
        AND a.phase_id = p.id
        AND p.name = "Pedido de Banca" /* Etapa é pedido de banca */
        AND (a.obs IS NULL OR a.obs NOT LIKE '%VF OK%')
        AND e.id NOT IN (SELECT enrollment_id
                         FROM dismissals d, dismissal_reasons dr
                         WHERE d.dismissal_reason_id = dr.id
                         AND dr.name = "Prazo") /* Não foi desligado ainda por prazo */
        /* passou mais que 90 dias da defesa OU (mais que 30 E não foi aprovado com restrição) */
        AND ((DATEDIFF(:data_consulta, e.thesis_defense_date) > 90)
            OR ((a.obs IS NULL OR a.obs NOT LIKE '%ACR%') AND (DATEDIFF(:data_consulta, e.thesis_defense_date) > 30)))
      SQL
    },
    { name: "Alunos que não entregaram a versão final da dissertação/tese (com orientadores)",
      description: "Alunos que não entregaram a versão final da dissertação/tese após 30 dias da defesa ou 90 no caso de aprovação condicional",
      params: [
        {
          name: "data_consulta",
          value_type: "Date"
        },
      ],
      notifications: [
        { title: "PROFS: Prazo vencido para entrega da versão final da dissertação/tese [Agendamento sugerido: Semanal 0]",
          frequency: "Manual",
          notification_offset: "0",
          query_offset: "0",
          individual: true,
          has_grades_report_pdf_attachment: false,
          template_type: "Liquid",
          to_template: "{{ advisor_email }}",
          subject_template: "Prazo de entrega de versão final vencido",
          body_template: <<~LIQUID
            {{ advisor_name }}

            Lembramos que venceu o prazo para entregar a versão final da tese/dissertação do seu orientando {{ student_name }}, defendida em {{ thesis_defense_date | localize: 'defaultdate' }}.

            O aluno deve entrar em contato com a secretaria imediatamente, apresentando uma carta em pdf com a justificativa do atraso, uma solicitação de prazo adicional de, no máximo, 15 dias, e a ciência de que será jubilado e perderá o título caso não cumpra o prazo solicitado. Essa carta deve ser assinada tanto pelo aluno quanto pelo orientador.

            Caso o aluno já tenha entregue a versão final ou já tenha entrado em contato com a secretaria, favor desconsiderar essa mensagem.
          LIQUID
        }
      ],
      sql: <<~SQL
        SELECT s.name AS student_name,
               s.email AS student_email,
               e.enrollment_number,
               p.name AS advisor_name,
               p.email AS advisor_email,
               e.thesis_defense_date
        FROM enrollments e, students s, advisements ad,
             professors p, accomplishments a, phases ph
        WHERE s.id = e.student_id
        AND e.id = ad.enrollment_id
        AND ad.professor_id = p.id
        AND a.enrollment_id = e.id
        AND a.phase_id = ph.id
        AND ph.name = "Pedido de Banca" /* Etapa é pedido de banca */
        AND (a.obs IS NULL OR a.obs NOT LIKE '%VF OK%')
        AND e.id NOT IN (SELECT d.enrollment_id
                         FROM dismissals d, dismissal_reasons dr
                         WHERE d.dismissal_reason_id = dr.id
                         AND dr.name = "Prazo") /* Não foi desligado ainda por prazo */
        /* passou mais que 90 dias da defesa OU (mais que 30 E não foi aprovado com restrição) */
        AND ((DATEDIFF(:data_consulta, e.thesis_defense_date) > 90)
        OR ((a.obs IS NULL OR a.obs NOT LIKE '%ACR%') AND (DATEDIFF(:data_consulta, e.thesis_defense_date) > 30)))
      SQL
    },
    { name: "Professores credenciados",
      description: "Gera lista de credenciados no formato exigido pelo sistema eletrônico de votação da UFF. É necessário realizar pós-processamento para remover acentos dos nomes.",
      params: [],
      notifications: [],
      sql: <<~SQL
        SELECT DISTINCT CONCAT("1", REPLACE(REPLACE(p.cpf, ".", ""), "-", "")), p.email, p.name
        FROM advisement_authorizations aa, professors p
        WHERE aa.professor_id = p.id
        ORDER BY p.name
      SQL
    },

  ])
end

queries.each do |query|
  puts query[:name]
  query_obj = Query.new(query.except(:params, :notifications))
  query[:params].map do |query_param|
    query_obj.params.build(query_param)
  end
  query_obj.save!

  Notification.create(
    query[:notifications].map do |notification_param|
      notification_param.merge({ query_id: query_obj.id })
    end
  )
end

# Assertions
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
  template_type: "Liquid",
  assertion_template: "Declaramos, para os devidos fins, que {{ nome_aluno }}, CPF: {{ cpf_aluno }}, matrícula {{ matricula_aluno }}, cumpriu todos os requisitos para obtenção do título de {% if nivel_aluno == 'Doutorado' %}Doutor{% else %}Mestre{% endif %}, tendo defendido, com aprovação, a Dissertação intitulada \"{{ titulo_tese }}\", em {{ data_defesa_tese | localize: 'longdate' }}.",
}
Assertion.create!(assertion)


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
  template_type: "Liquid",
  assertion_template: "
        Declaro, para os devidos fins, que {{ nome_aluno }} cursou como Aluno Avulso as seguintes disciplinas do Programa de Pós-Graduação em Computação, nos termos do Art. 15 do Regulamento dos Programas de Pós-Graduação Stricto Sensu da Universidade Federal Fluminense.

        {% for record in records %}
          Nome da disciplina: {{ record.nome_disciplina }}
          Carga horaria total: {{ record.carga_horaria }}
          Período: {{ record.ano_disciplina }}/{{ record.semestre_disciplina }}
          Nota: {{ record.nota | divided_by: 10.0 }}
          Situação final: {{ record.situacao }}

        {% endfor %}"
}
Assertion.create!(assertion)


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

Assertion.reset_column_information
assertion = {
  name: "Declaração de participante externo em defesa de tese",
  student_can_generate: false,
  query_id: query_obj.id,
  template_type: "Liquid",
  assertion_template: "A quem possa interessar, declaramos que {{ nome_professor }} participou da banca de defesa da dissertação de {{ nivel_aluno }} de {{ nome_aluno }}, no dia {{ data | localize: 'longdate' }}.",
}
Assertion.create!(assertion)
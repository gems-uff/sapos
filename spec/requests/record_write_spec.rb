# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Escrita por registro, julgada pelo efeito no banco — issue #742.
#
# O status não serve de critério: o active_scaffold recusa um update_column
# alheio respondendo 200, com o erro em JavaScript. O que prova a recusa é o
# registro não ter mudado. Cada linha de ESCRITAS diz quem tenta, o quê, sobre
# qual registro do conjunto (spec/support/ability_dataset.rb), e se o banco
# deve mudar — é a intenção, escrita. Quando há ação correspondente no
# Ability, a linha confere também que ele concorda, para que uma regra que
# mude quebre os dois lados.
#
# As linhas de "forja" mandam um campo que a tela não oferece àquele papel
# (o dono do artigo, o professor do projeto, o professor da turma, a turma da
# inscrição). Quem barra são as validações dos modelos, que consultam o Ability
# do usuário da requisição.
RSpec.describe "Escrita por registro, pelo efeito no banco", type: :request do
  include AbilityDataset

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  def rec(name)
    @labels.key(name) || raise("rótulo #{name} não existe no conjunto de dados")
  end

  def tentar(user, verb, path, params = {}, xhr: false)
    sign_in user
    process(verb, path, params: params, xhr: xhr, env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR })
  rescue CanCan::AccessDenied, ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed,
         ActiveRecord::RecordNotFound
    nil
  end

  # Fotografia do que a escrita poderia mudar: os atributos, ou a ausência.
  def estado(record)
    record.class.unscoped.find_by(id: record.id)&.attributes
  end

  def self.escrita(descricao, usuario:, notas: nil, verbo:, caminho:, alvo:, params: {}, muda:, acao: nil, xhr: false)
    it "#{descricao}: #{muda ? 'muda' : 'não muda'} o banco" do
      post_grades(notas)
      registro = rec(alvo)
      user = @users[usuario]
      if acao
        expect(Ability.new(User.find(user.id)).can?(acao, registro)).to eq(muda),
          "o Ability discorda da intenção para #{acao} em #{alvo}"
      end
      antes = estado(registro)
      tentar(user, verbo, caminho.call(registro, self), params.is_a?(Proc) ? params.call(self) : params, xhr: xhr)
      depois = estado(registro)

      if muda
        expect(depois).not_to eq(antes)
      else
        expect(depois).to eq(antes)
      end
    end
  end

  artigo = ->(r, _) { "/papers/#{r.id}" }
  projeto = ->(r, _) { "/grants/#{r.id}" }
  inscricao = ->(r, _) { "/class_enrollments/#{r.id}" }

  describe "professor, sobre artigos e projetos" do
    escrita "altera o próprio artigo", usuario: :professor, verbo: :patch, caminho: artigo,
      alvo: "paper_a", params: { record: { reference: "Alterado" } }, muda: true, acao: :update
    escrita "altera o artigo de outro professor", usuario: :professor, verbo: :patch, caminho: artigo,
      alvo: "paper_b", params: { record: { reference: "Alterado" } }, muda: false, acao: :update
    escrita "passa o próprio artigo para outro professor (forja)", usuario: :professor, verbo: :patch,
      caminho: artigo, alvo: "paper_a", params: ->(t) { { record: { owner: t.rec("prof_b").id } } }, muda: false
    escrita "apaga o próprio artigo", usuario: :professor, verbo: :delete, caminho: artigo,
      alvo: "paper_a", muda: true, acao: :destroy
    escrita "apaga o artigo de outro professor", usuario: :professor, verbo: :delete, caminho: artigo,
      alvo: "paper_b", muda: false, acao: :destroy

    escrita "altera o próprio projeto", usuario: :professor, verbo: :patch, caminho: projeto,
      alvo: "grant_a", params: { record: { title: "Alterado" } }, muda: true, acao: :update
    escrita "altera o projeto de outro professor", usuario: :professor, verbo: :patch, caminho: projeto,
      alvo: "grant_b", params: { record: { title: "Alterado" } }, muda: false, acao: :update
    escrita "passa o próprio projeto para outro professor (forja)", usuario: :professor, verbo: :patch,
      caminho: projeto, alvo: "grant_a", params: ->(t) { { record: { professor: t.rec("prof_b").id } } }, muda: false
    escrita "apaga o projeto de outro professor", usuario: :professor, verbo: :delete, caminho: projeto,
      alvo: "grant_b", muda: false, acao: :destroy

    escrita "remove autoria do próprio artigo", usuario: :professor, verbo: :delete,
      caminho: ->(r, _) { "/paper_professors/#{r.id}" }, alvo: "pp_a", muda: true, acao: :destroy
    escrita "remove autoria do artigo de outro professor", usuario: :professor, verbo: :delete,
      caminho: ->(r, _) { "/paper_professors/#{r.id}" }, alvo: "pp_b", muda: false, acao: :destroy
    escrita "remove aluno do próprio artigo", usuario: :professor, verbo: :delete,
      caminho: ->(r, _) { "/paper_students/#{r.id}" }, alvo: "ps_a", muda: true, acao: :destroy
    escrita "remove aluno do artigo de outro professor", usuario: :professor, verbo: :delete,
      caminho: ->(r, _) { "/paper_students/#{r.id}" }, alvo: "ps_b", muda: false, acao: :destroy
    # A tela mostra o período travado a quem não gerencia: é o quadriênio que o
    # sistema preencheu.
    escrita "troca o período do próprio artigo (forja)", usuario: :professor, verbo: :patch,
      caminho: artigo, alvo: "paper_a", params: { record: { period: "1900-1903" } }, muda: false
    escrita "troca o período do próprio artigo pela edição em linha (forja)", usuario: :professor, verbo: :post,
      caminho: ->(r, _) { "/papers/#{r.id}/update_column" }, alvo: "paper_a",
      params: { column: "period", value: "1900-1903" }, muda: false, xhr: true
    escrita "a secretaria troca o período do artigo", usuario: :secretaria, verbo: :patch,
      caminho: artigo, alvo: "paper_a", params: { record: { period: "1900-1903" } }, muda: true
    # Controle da forja do dono: a mesma troca, feita por quem gerencia os
    # artigos, grava -- o que recusa o professor é a guarda, não outra validação.
    escrita "a secretaria passa o artigo para outro professor", usuario: :secretaria, verbo: :patch,
      caminho: artigo, alvo: "paper_a", params: ->(t) { { record: { owner: t.rec("prof_b").id } } }, muda: true

    it "não cria artigo com período em branco nem com período escolhido (forja)" do
      criar = lambda do |periodo|
        tentar(@users[:professor], :post, "/papers", { record: {
          reference: "Artigo novo", kind: Paper::JOURNAL, doi_issn_event: "10.0/x", reason_justify: "motivo",
          order: 5, owner: rec("prof_a").id, period: periodo
        } })
      end

      expect { criar.call(""); criar.call("1900-1903") }.not_to change(Paper, :count)
      expect { criar.call(CustomVariable.quadrennial_period) }.to change(Paper, :count).by(1)
    end
    escrita "leva a autoria do próprio artigo para o artigo de outro professor (forja)", usuario: :professor,
      verbo: :patch, caminho: ->(r, _) { "/paper_professors/#{r.id}" }, alvo: "pp_a",
      params: ->(t) { { record: { paper: t.rec("paper_b").id } } }, muda: false
    escrita "leva o aluno do próprio artigo para o artigo de outro professor (forja)", usuario: :professor,
      verbo: :patch, caminho: ->(r, _) { "/paper_students/#{r.id}" }, alvo: "ps_a",
      params: ->(t) { { record: { paper: t.rec("paper_b").id } } }, muda: false

    # O subformulário do artigo aceita, pelo id, uma linha que já existe. A
    # linha de autoria do artigo de outro professor não vem para o artigo de
    # quem envia.
    describe "linha de autoria de outro artigo, pelo subformulario do proprio" do
      def puxar(associacao, alheia)
        proprias = rec("paper_a").public_send(associacao).to_h { |linha| [linha.id.to_s, { id: linha.id.to_s }] }
        tentar(@users[:professor], :patch, "/papers/#{rec('paper_a').id}",
          { record: { associacao => proprias.merge(alheia.id.to_s => { id: alheia.id.to_s }) } })
      end

      it "não traz o docente do artigo de outro professor" do
        expect { puxar(:paper_professors, rec("pp_b")) }.not_to change { rec("pp_b").reload.paper_id }
      end

      it "não traz o aluno do artigo de outro professor" do
        expect { puxar(:paper_students, rec("ps_b")) }.not_to change { rec("ps_b").reload.paper_id }
      end

      # Controle: reenviar as próprias linhas não muda nada e não é recusado.
      it "mantém as linhas do próprio artigo" do
        proprias = rec("paper_a").paper_professors.to_h { |linha| [linha.id.to_s, { id: linha.id.to_s }] }
        tentar(@users[:professor], :patch, "/papers/#{rec('paper_a').id}",
          { record: { reference: "Referencia nova", paper_professors: proprias } })

        expect(rec("paper_a").reload.reference).to eq("Referencia nova")
        expect(rec("pp_a").reload.paper_id).to eq(rec("paper_a").id)
      end
    end

    # A criação é liberada à classe (o subform do artigo precisa dela); o que
    # prende a linha nova ao artigo de quem a cria é a validação do modelo.
    describe "linha de autoria nova" do
      def autorias(artigo)
        [PaperProfessor.where(paper: artigo).count, PaperStudent.where(paper: artigo).count]
      end

      def criar_autorias(artigo)
        tentar(@users[:professor], :post, "/paper_professors",
          { record: { paper: artigo.id, professor: rec("prof_c").id } })
        tentar(@users[:professor], :post, "/paper_students",
          { record: { paper: artigo.id, student: rec("st_b").id } })
      end

      it "não entra no artigo de outro professor" do
        expect { criar_autorias(rec("paper_b")) }.not_to change { autorias(rec("paper_b")) }
      end

      it "entra no próprio artigo" do
        expect { criar_autorias(rec("paper_a")) }.to change { autorias(rec("paper_a")) }.from([1, 1]).to([2, 2])
      end
    end
  end

  describe "professor, sobre notas" do
    escrita "lança observação na própria turma, com nota em todo semestre", usuario: :professor,
      notas: "yes_all_semesters", verbo: :patch, caminho: inscricao, alvo: "ce_a_atual",
      params: { record: { obs: "Alterado" } }, muda: true, acao: :post_grades
    escrita "lança observação na turma de outro professor", usuario: :professor,
      notas: "yes_all_semesters", verbo: :patch, caminho: inscricao, alvo: "ce_b_atual",
      params: { record: { obs: "Alterado" } }, muda: false, acao: :post_grades
    escrita "lança observação em turma antiga, com nota só no semestre corrente", usuario: :professor,
      notas: "yes", verbo: :patch, caminho: inscricao, alvo: "ce_a_antiga",
      params: { record: { obs: "Alterado" } }, muda: false, acao: :post_grades
    escrita "lança observação na própria turma, sem lançamento de nota", usuario: :professor,
      notas: nil, verbo: :patch, caminho: inscricao, alvo: "ce_a_atual",
      params: { record: { obs: "Alterado" } }, muda: false, acao: :post_grades
    escrita "move a inscrição para a turma de outro professor (forja)", usuario: :professor,
      notas: "yes_all_semesters", verbo: :patch, caminho: inscricao, alvo: "ce_a_atual",
      params: ->(t) { { record: { course_class: t.rec("cc_b_atual").id } } }, muda: false
    escrita "passa a própria turma para outro professor (forja)", usuario: :professor,
      notas: "yes_all_semesters", verbo: :patch, caminho: ->(r, _) { "/course_classes/#{r.id}" },
      alvo: "cc_a_atual", params: ->(t) { { record: { professor: t.rec("prof_b").id } } }, muda: false
  end

  describe "professor, sobre pedidos de inscrição" do
    validar = ->(r, _) { "/class_enrollment_requests/#{r.id}/set_valid" }
    escrita "valida o item do pedido do orientando", usuario: :professor, verbo: :put, caminho: validar,
      alvo: "cer_a_solicitada", muda: true, acao: :update
    escrita "valida o item do pedido de quem não orienta", usuario: :professor, verbo: :put,
      caminho: validar, alvo: "cer_b_solicitada", muda: false, acao: :update
    escrita "reabre o item já efetivado", usuario: :professor, verbo: :put, caminho: validar,
      alvo: "cer_a_efetivada", muda: false, acao: :update
    escrita "apaga o pedido do orientando", usuario: :professor, verbo: :delete,
      caminho: ->(r, _) { "/enrollment_requests/#{r.id}" }, alvo: "er_a", muda: false, acao: :destroy
  end

  describe "professor, sobre o processo seletivo" do
    candidatura = ->(r, _) { "/admission_applications/#{r.id}" }
    escrita "altera a candidatura em que não tem pendência", usuario: :professor, verbo: :patch,
      caminho: candidatura, alvo: "app_outro", params: { record: { name: "Alterado" } }, muda: false, acao: :update
    escrita "apaga a candidatura em que tem pendência", usuario: :professor, verbo: :delete,
      caminho: candidatura, alvo: "app_pendente", muda: false, acao: :destroy
  end

  describe "aluno" do
    escrita "altera a própria matrícula", usuario: :aluno, verbo: :patch,
      caminho: ->(r, _) { "/enrollments/#{r.id}" }, alvo: "enr_a_aprovada",
      params: { record: { obs: "Alterado" } }, muda: false, acao: :update
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A página pública da inscrição, como o candidato a alcança e o que ela lhe
# mostra. O candidato não tem login nem papel: o que o separa das outras
# inscrições é o código, e o que o separa do trabalho da comissão é o que cada
# fase e cada ranking liberam para ele.
RSpec.describe "Pagina da inscricao vista pelo candidato", type: :request do
  # Entra pelo formulário de recuperação, com o e-mail e o código, e devolve o
  # texto da página da inscrição.
  def pagina_do_candidato(processo, inscricao)
    post find_admissions_path, params: {
      admissions_admission_application: { email: inscricao.email, token: inscricao.token },
    }
    get admission_apply_path(admission_id: processo.simple_id, id: inscricao.token)
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body).text.squish
  end

  describe "o codigo e a fronteira da inscricao" do
    before(:each) do
      @template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
      datas = {
        start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
      }
      @livre = FactoryBot.create(
        :admission_process, name: "Sem sessao", simple_url: "pagina-sem-sessao",
        form_template: @template, require_session: false, **datas
      )
      @outro = FactoryBot.create(
        :admission_process, name: "Outro", simple_url: "pagina-outro",
        form_template: @template, require_session: false, **datas
      )
      @com_sessao = FactoryBot.create(
        :admission_process, name: "Com sessao", simple_url: "pagina-com-sessao",
        form_template: @template, require_session: true, **datas
      )
      @inscricao = create_application(@livre, name: "Dono", fields: { "Dado" => "dado-do-dono" })
    end

    def recusada?(processo, codigo)
      get admission_apply_path(admission_id: processo.simple_id, id: codigo)
      response.redirect? && response.location.end_with?(admissions_path) && !response.body.include?("dado-do-dono")
    end

    # Controle: o código inteiro, no processo dele, abre.
    it "abre com o codigo inteiro no processo da inscricao" do
      get admission_apply_path(admission_id: @livre.simple_id, id: @inscricao.token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dado-do-dono")
    end

    it "nao abre com o codigo certo no endereco de outro processo" do
      expect(recusada?(@outro, @inscricao.token)).to be(true)
    end

    it "nao abre so com o identificador, a parte do codigo que a secretaria e os relatorios veem" do
      expect(recusada?(@livre, @inscricao.identifier)).to be(true)
    end

    it "nao trata o codigo como padrao de busca" do
      expect(recusada?(@livre, "#{@inscricao.identifier}%")).to be(true)
      expect(recusada?(@livre, "%")).to be(true)
      expect(recusada?(@livre, @inscricao.token.tr("2346789BCDFGHJKMPQRTVWXY", "_"))).to be(true)
    end

    it "nao aceita na recuperacao o codigo certo com o e-mail de outra pessoa" do
      post find_admissions_path, params: {
        admissions_admission_application: { email: "outra@example.com", token: @inscricao.token },
      }

      expect(response).to redirect_to(admissions_path)
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.application_not_found"))
    end

    it "nao abre o processo com sessao so com o codigo, e nao altera a inscricao" do
      com_sessao = create_application(@com_sessao, name: "Dono", fields: { "Dado" => "dado-do-dono" })

      expect(recusada?(@com_sessao, com_sessao.token)).to be(true)
      put admission_apply_path(admission_id: @com_sessao.simple_id, id: com_sessao.token), params: { record: {
        filled_form_attributes: {
          id: com_sessao.filled_form.id, enable_submission: "1",
          fields_attributes: { "0" => { id: com_sessao.filled_form.fields.first.id, value: "adulterado" } },
        },
      } }
      expect(com_sessao.filled_form.fields.first.reload.value).to eq("dado-do-dono")
    end

    it "mostra a inscricao de processo encerrado, sem oferecer a edicao" do
      encerrado = create_closed_admission_process(@template, simple_url: "pagina-encerrado")
      antiga = create_application(encerrado, name: "Antigo", fields: { "Dado" => "dado-antigo" })

      get admission_apply_path(admission_id: encerrado.simple_id, id: antiga.token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dado-antigo")
      expect(response.body).not_to include(
        edit_admission_apply_path(admission_id: encerrado.simple_id, id: antiga.token)
      )
    end
  end

  describe "o que a comissao produz" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      @admin = create_confirmed_user([role], "pagina-candidato-admin@example.com")
      allow(Notifier).to receive(:send_emails)
    end

    # Cartas de recomendação, formulário compartilhado, consolidação e ranking:
    # processo 3 de spec/fixtures/admissions/workflows.json.
    context "com cartas, avaliacao compartilhada, consolidacao e ranking" do
      before(:each) do
        workflow = AdmissionsWorkflowLoader.load(process_id: 3)
        @process = workflow.process
        homologacao, @avaliacao, entrevista = workflow.phase_links.map(&:admission_phase)
        secretaria = workflow.committee_users[1].first
        linha = workflow.committee_users[3]
        @vagas = workflow.ranking_links.first.ranking_config
        compartilhado = Admissions::AdmissionPhaseResult::SHARED

        @kim = apply_as_candidate(
          @process, name: "Kim", email: "kim@example.com", values: { "Linha de pesquisa" => "Linha 1" },
          letters: [{ name: "Rec Um", email: "rec-um@example.com", telephone: "2199" },
                    { name: "Rec Dois", email: "rec-dois@example.com" }]
        )
        @kim.letter_requests.each do |carta|
          fill_letter_as_recommender(@process, carta, { "Relação com o candidato" => "Orientador", "Avaliação" => "Excelente" })
        end

        sign_in @admin
        consolidate_phase_as_staff(@process, nil)
        sign_out @admin
        sign_in secretaria
        submit_phase_form(@kim, homologacao, homologacao.shared_form, { "Homologação" => "Deferida" }, mode: compartilhado)
        sign_out secretaria
        sign_in @admin
        consolidate_phase_as_staff(@process, homologacao)
        sign_out @admin
        sign_in linha.first
        submit_phase_form(
          @kim, @avaliacao, @avaliacao.shared_form,
          { "Nota de formação" => "9", "Nota de produção" => "8", "Nota de experiência" => "10" }, mode: compartilhado
        )
        sign_out linha.first
        sign_in @admin
        @process.update!(end_date: Date.current - 1)
        consolidate_phase_as_staff(@process, @avaliacao)
        sign_out @admin
        sign_in linha.last
        submit_phase_form(
          @kim, entrevista, entrevista.shared_form,
          { "Nota de apresentação" => "5", "Nota de arguição" => "4", "Situação sugerida" => "Regular" }, mode: compartilhado
        )
        sign_out linha.last
        sign_in @admin
        consolidate_phase_as_staff(@process, entrevista)
        sign_out @admin
        expect(position_and_machine(workflow.ranking_links.first, @kim)).to eq([1, "Ampla concorrência"])
      end

      it "mostra a inscricao e a quem as cartas foram pedidas, e nada da comissao enquanto nada e liberado" do
        pagina = pagina_do_candidato(@process, @kim)

        expect(pagina).to include("Linha 1")
        expect(pagina).to include("Rec Um", "rec-dois@example.com")
        expect(pagina).not_to include("Nota de formação")
        expect(pagina).not_to include("Nota final")
        expect(pagina).not_to include(@vagas.name)
      end

      it "mostra o formulario compartilhado so da fase que o libera" do
        @avaliacao.update!(candidate_can_see_shared: true)

        pagina = pagina_do_candidato(@process, @kim)

        expect(pagina).to include("Nota de formação")
        expect(pagina).not_to include("Nota de apresentação")
        expect(pagina).not_to include("Nota final")
      end

      it "mostra a consolidacao so da fase que a libera" do
        @avaliacao.update!(candidate_can_see_consolidation: true)

        pagina = pagina_do_candidato(@process, @kim)

        expect(pagina).to include("Nota final")
        expect(pagina).not_to include("Nota de formação")
      end

      it "mostra o ranking so quando a configuracao dele o libera" do
        @vagas.update!(candidate_can_see: true)

        pagina = pagina_do_candidato(@process, @kim)

        expect(pagina).to include(@vagas.name)
        expect(pagina).not_to include("Nota de formação")
        expect(pagina).not_to include("Nota final")
      end

      it "nunca mostra o conteudo das cartas nem o codigo de acesso delas, com tudo liberado" do
        Admissions::AdmissionPhase.update_all(
          candidate_can_see_shared: true, candidate_can_see_member: true, candidate_can_see_consolidation: true
        )
        Admissions::RankingConfig.update_all(candidate_can_see: true)

        pagina = pagina_do_candidato(@process, @kim)

        expect(pagina).to include("Rec Um")
        expect(pagina).not_to include("Excelente")
        expect(pagina).not_to include("Orientador")
        @kim.letter_requests.each do |carta|
          expect(carta.access_token).to be_present
          expect(response.body).not_to include(carta.access_token)
        end
      end
    end

    # Um formulário por membro da comissão: processo 2 do mesmo arquivo.
    context "com avaliacao individual" do
      before(:each) do
        workflow = AdmissionsWorkflowLoader.load(process_id: 2)
        @process = workflow.process
        homologacao, @avaliacao = workflow.phase_links.map(&:admission_phase)
        secretaria = workflow.committee_users[1].first

        @gil = apply_as_candidate(@process, name: "Gil", email: "gil@example.com", values: { "Data de nascimento" => "01/01/1990" })
        sign_in @admin
        consolidate_phase_as_staff(@process, nil)
        sign_out @admin
        sign_in secretaria
        submit_phase_form(
          @gil, homologacao, homologacao.shared_form, { "Homologação" => "Deferida" },
          mode: Admissions::AdmissionPhaseResult::SHARED
        )
        sign_out secretaria
        sign_in @admin
        consolidate_phase_as_staff(@process, homologacao)
        sign_out @admin
        workflow.committee_users[2].each_with_index do |membro, i|
          sign_in membro
          submit_phase_form(@gil, @avaliacao, @avaliacao.member_form, {
            "Nota de formação" => "9", "Nota de experiência" => "8", "Nota de projeto" => "7",
            "Parecer" => "Parecer do membro #{i + 1}",
          }, user: membro)
          sign_out membro
        end
      end

      it "nao mostra o parecer de membro nenhum enquanto a fase nao libera" do
        expect(pagina_do_candidato(@process, @gil)).not_to include("Parecer do membro")
      end

      it "mostra o parecer de cada membro quando a fase libera" do
        @avaliacao.update!(candidate_can_see_member: true)

        expect(pagina_do_candidato(@process, @gil)).to include("Parecer do membro 1", "Parecer do membro 2")
      end
    end
  end
end

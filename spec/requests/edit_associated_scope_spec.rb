# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A linha de subformulário do active_scaffold tem uma rota em todo scaffold:
# GET edit_associated?child_association=<coluna>&associated_id=<id>, que
# devolve o registro associado como linha de formulário, com os valores nas
# células. A gem a aceita para QUALQUER coluna de associação do scaffold,
# ofereça-a o formulário ou não, e busca o registro pelo id cru
# (Subform#find_associated_record), sem passar pelo que o Ability deixa o
# usuário ler. Na forma de coleção (sem :id) o pai é um registro novo: basta
# poder alterar a classe, o que o CanCan concede a quem tem regra condicional.
#
# O que segura a linha é só a permissão de leitura da CLASSE associada, coluna
# a coluna: classe que o papel não lê de jeito nenhum vem como linha vazia.
# Classe que ele lê sob condição vem inteira, cumpra o registro a condição ou
# não -- e é o caso do professor no processo seletivo, que lê formulário e
# resultado só das candidaturas em que tem pendência.
RSpec.describe "Linha de subformulario pedida pelo id", type: :request do
  include AbilityDataset

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  def rec(name)
    @labels.key(name) || raise("rótulo #{name} não existe no conjunto de dados")
  end

  def remoto
    { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
  end

  # O corpo que a rota devolve; a recusa não devolve corpo nenhum.
  def linha(user, caminho, coluna, registro)
    sign_in user
    get caminho, params: { child_association: coluna, associated_id: registro.id }, xhr: true, env: remoto
    response.body
  rescue CanCan::AccessDenied, ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed,
         ActiveRecord::RecordNotFound
    ""
  end

  # Tudo que um pedido poderia gravar, fora o rastro do login: a sessão, o
  # rastreio que o Devise grava no usuário a cada pedido, e a versão que o
  # PaperTrail registra dessa gravação.
  def fotografia
    conexao = ActiveRecord::Base.connection
    (conexao.tables - %w[sessions users versions]).sort.index_with do |tabela|
      conexao.select_all("SELECT * FROM #{conexao.quote_table_name(tabela)}").to_a
    end
  end

  describe "para o professor, no processo seletivo" do
    before(:each) do
      @professor = @users[:professor]
      @com_pendencia = rec("app_pendente")
      @sem_pendencia = rec("app_sem")
      FactoryBot.create(:filled_form_field, filled_form: @com_pendencia.filled_form, value: "RESPOSTA-COM-PENDENCIA")
      FactoryBot.create(:filled_form_field, filled_form: @sem_pendencia.filled_form, value: "RESPOSTA-SEM-PENDENCIA")
    end

    it "nao devolve o formulario da candidatura em que ele nao tem pendencia" do
      corpo = linha(@professor, "/admission_applications/edit_associated", "filled_form", @sem_pendencia.filled_form)

      expect(corpo).not_to include("RESPOSTA-SEM-PENDENCIA")
    end

    it "nem quando o pai e a candidatura em que ele tem pendencia" do
      corpo = linha(
        @professor, "/admission_applications/#{@com_pendencia.id}/edit_associated", "filled_form",
        @sem_pendencia.filled_form
      )

      expect(corpo).not_to include("RESPOSTA-SEM-PENDENCIA")
    end

    # O rótulo do campo de arquivo é o endereço de download, e a rota de
    # download vale pelo hash, sem login (spec/requests/files_download_spec.rb).
    it "nao devolve o endereco de download do documento do candidato" do
      formulario = @sem_pendencia.filled_form
      campo = FactoryBot.create(
        :form_field, form_template: formulario.form_template, field_type: Admissions::FormField::FILE
      )
      documento = FactoryBot.create(
        :filled_form_field, filled_form: formulario, form_field: campo, value: nil,
        file: Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", "user.png"), "image/png")
      )

      corpo = linha(@professor, "/admission_applications/edit_associated", "filled_form", formulario)

      expect(corpo).not_to include(documento.file.medium_hash)
    end

    it "nao devolve o resultado de ranking da candidatura em que ele nao tem pendencia" do
      ranking = rec("ranking_app_sem")
      FactoryBot.create(:filled_form_field, filled_form: ranking.filled_form, value: "POSICAO-SEM-PENDENCIA")

      corpo = linha(@professor, "/admission_applications/edit_associated", "rankings", ranking)

      expect(corpo).not_to include("POSICAO-SEM-PENDENCIA")
    end

    it "nao devolve nada ao professor que nao tem pendencia em candidatura nenhuma" do
      outro = user_with([Role.find(Role::ROLE_PROFESSOR)], "professor_sem_pendencia", professor: @prof_b)
      expect(Admissions::AdmissionPendency.where(user_id: outro.id)).to be_empty

      corpo = linha(outro, "/admission_applications/edit_associated", "filled_form", @sem_pendencia.filled_form)

      expect(corpo).not_to include("RESPOSTA-SEM-PENDENCIA")
    end

    # A linha nova de um subformulario em abas chega com a aba na URL
    # (tabbed_by, value, value_type), e a gem busca o registro da aba pelo id
    # cru, na classe que a URL disser. O SAPOS nao tem subformulario em abas:
    # a linha vem como a linha nova de sempre, sem a busca.
    it "ignora a aba que a URL pede para a linha nova" do
      sign_in @professor
      expect(User).not_to receive(:find)

      get "/admission_applications/edit_associated", xhr: true, env: remoto, params: {
        child_association: "filled_form", tabbed_by: "form_template", value: @users[:secretaria].id, value_type: "User",
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("association-record-new")
    end

    # Controle: o Ability nega os dois registros, e as telas obedecem.
    it "nao abre o mesmo formulario nem a mesma candidatura pela ficha" do
      sign_in @professor
      expect {
        get "/filled_forms/#{@sem_pendencia.filled_form.id}", env: remoto
      }.to raise_error(ActiveRecord::RecordNotFound)

      sign_in @professor
      expect {
        get "/admission_applications/#{@sem_pendencia.id}", env: remoto
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    # Controle: o cenário está montado -- onde ele pode ler, a resposta aparece.
    it "le pela ficha a resposta da candidatura em que tem pendencia" do
      sign_in @professor
      get "/filled_forms/#{@com_pendencia.filled_form.id}", env: remoto

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("RESPOSTA-COM-PENDENCIA")
    end

    # Controle: a tela não oferece o caminho. O formulário da candidatura só
    # tem os formulários de fase; nenhuma linha de subformulário sai dele.
    it "nao recebe a rota no formulario de edicao da candidatura" do
      sign_in @professor
      get "/admission_applications/#{@com_pendencia.id}/edit", env: remoto

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("edit_associated")
    end

    # Controle: a autorização da rota está viva -- quem não altera
    # candidatura não passa, e a candidatura sem pendência não serve de pai.
    it "e barrado na rota quando nao altera candidatura, e no pai que nao e dele" do
      sign_in @users[:aluno]
      expect {
        get "/admission_applications/edit_associated", xhr: true, env: remoto,
          params: { child_association: "filled_form", associated_id: @sem_pendencia.filled_form.id }
      }.to raise_error(CanCan::AccessDenied)

      sign_in @professor
      expect {
        get "/admission_applications/#{@sem_pendencia.id}/edit_associated", xhr: true, env: remoto,
          params: { child_association: "filled_form", associated_id: @sem_pendencia.filled_form.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    # A rota prende o registro ao pai só em memória, e o formulário da
    # candidatura não tem a coluna: a linha mandada de volta é ignorada.
    it "nao grava nada, nem ao pedir a linha nem ao manda-la de volta pelo formulario" do
      antes = fotografia

      linha(
        @professor, "/admission_applications/#{@com_pendencia.id}/edit_associated", "filled_form",
        @sem_pendencia.filled_form
      )
      expect(fotografia).to eq(antes)

      sign_in @professor
      patch "/admission_applications/#{@com_pendencia.id}", env: remoto, params: { record: {
        filled_form: { id: @sem_pendencia.filled_form.id, is_filled: "1" },
        rankings: { "0" => { id: rec("ranking_app_sem").id } },
      } }
      expect(fotografia).to eq(antes)
    end
  end

  # A mesma pergunta a todo scaffold: cada perfil que não é administrador pede,
  # em cada scaffold cuja classe ele pode alterar e por cada coluna de
  # associação, registros que o Ability não o deixa ler. A linha pode vir
  # vazia ou a rota pode recusar; o que não pode é vir célula (form-element).
  describe "em todo scaffold" do
    def scaffolds
      Rails.application.eager_load!
      ApplicationController.descendants.filter_map do |controller|
        next unless controller.respond_to?(:active_scaffold_config) && controller.action_methods.include?("edit_associated")

        config = begin
          controller.active_scaffold_config
        rescue StandardError
          nil
        end
        [controller, config] if config
      end
    end

    # A linha de outro scaffold, montada fora da tela dela, quebra em helper
    # com frequência: erro não é célula. O caminho sai das rotas, fora do
    # rescue -- scaffold sem a rota tem de fazer barulho, não passar por erro.
    def celulas?(user, controller, coluna, registro)
      caminho = url_for(controller: "/#{controller.controller_path}", action: "edit_associated", only_path: true)
      begin
        linha(user, caminho, coluna.name, registro).include?("form-element")
      rescue StandardError
        false
      end
    end

    it "nenhum perfil recebe celula de registro que o Ability nao o deixa ler" do
      vazamentos = []
      lidos_com_celula = 0

      AbilityDataset::PERFIS.each do |p|
        next if %w[visitante administrador].include?(p.first)

        user = vestir_perfil(p)
        ability = Ability.new(user)
        scaffolds.each do |controller, config|
          next unless ability.can?(:update, config.model)

          config.columns.select(&:association).each do |coluna|
            next if coluna.association.polymorphic?

            lidos, negados = coluna.association.klass.unscoped.limit(40).partition { |r| ability.can?(:read, r) }
            lidos_com_celula += 1 if lidos.any? && celulas?(user, controller, coluna, lidos.first)
            negados.first(3).each do |registro|
              next unless celulas?(user, controller, coluna, registro)

              vazamentos << "#{p.first} | #{controller.controller_path} | #{coluna.name} | " \
                            "#{registro.class.name} #{@labels[registro] || registro.id}"
            end
          end
        end
      end

      # Controle: a sonda enxerga célula quando o registro é legível.
      expect(lidos_com_celula).to be_positive
      expect(vazamentos).to eq([])
    end
  end
end

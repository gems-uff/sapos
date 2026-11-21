# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# As cinco regras de leitura de FilledForm do membro da comissão, juntas —
# issue #742.
#
# O formulário preenchido tem cinco donos possíveis: a candidatura, a carta de
# recomendação, a avaliação do membro, o resultado de fase e o resultado de
# ranking. O professor lê o que é dele: o formulário cuja candidatura tem uma
# pendência em seu nome e a avaliação que ele mesmo fez. A regra da candidatura
# ficou comentada de 2024 até o cancancan 3.7.0, porque a versão da época
# errava o SQL do accessible_by ao combinar as cinco; por isso cada exemplo
# daqui cobra as cinco de uma vez, pelo can? e pelo accessible_by.
#
# Os formulários são os do conjunto de dados das matrizes
# (spec/support/ability_dataset.rb): doze, um de cada dono, sobre candidatura
# com pendência do professor, de outro usuário, compartilhada e sem pendência.
RSpec.describe "Formulario preenchido lido pelo membro da comissao", type: :model do
  include ActiveSupport::Testing::TimeHelpers
  include AbilityDataset

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  def formulario(rotulo)
    @labels.key(rotulo) || raise("formulario #{rotulo} nao existe no conjunto de dados")
  end

  def formularios
    @labels.select { |registro, _| registro.is_a?(Admissions::FilledForm) }
  end

  def rotulos_listados(ability, escopo = Admissions::FilledForm.all)
    escopo.accessible_by(ability).map { |registro| @labels.fetch(registro) }
  end

  def do_professor
    %w[ff_app_pendente ff_avaliacao_professor ff_carta_app_pendente ff_ranking_app_pendente ff_resultado_app_pendente]
  end

  context "o professor com pendencia numa candidatura" do
    before(:each) do
      @ability = Ability.new(vestir_perfil(perfil("professor (sem lançamento de nota)")))
    end

    it "le o formulario de cada um dos cinco donos" do
      do_professor.each do |rotulo|
        expect(@ability.can?(:read, formulario(rotulo))).to be(true), rotulo
      end
    end

    it "nao le o formulario de candidatura em que nao tem pendencia, nem a avaliacao de outro membro" do
      expect(formularios.size).to eq(12)
      (formularios.values - do_professor).each do |rotulo|
        expect(@ability.can?(:read, formulario(rotulo))).to be(false), rotulo
      end
    end

    it "nao cria, altera nem apaga formulario nenhum" do
      formularios.each do |registro, rotulo|
        %i[create update destroy].each do |acao|
          expect(@ability.can?(acao, registro)).to be(false), "#{acao} #{rotulo}"
        end
      end
    end

    it "lista pelo accessible_by exatamente os que le, cada um uma vez" do
      expect(rotulos_listados(@ability).sort).to eq(do_professor)
    end

    # O que a listagem do active_scaffold faz sobre o accessible_by: conta,
    # ordena e pagina.
    it "conta, ordena e pagina a lista sem perder nem repetir formulario" do
      escopo = Admissions::FilledForm.accessible_by(@ability)

      expect(escopo.count).to eq(5)
      expect(escopo.distinct.count).to eq(5)
      paginas = [0, 2, 4].flat_map do |inicio|
        rotulos_listados(@ability, Admissions::FilledForm.order(id: :desc).limit(2).offset(inicio))
      end
      expect(paginas.sort).to eq(do_professor)
    end
  end

  it "da a outro membro so os formularios dele" do
    ability = Ability.new(vestir_perfil(perfil("professor e coordenador, atuando como professor")))

    expect(rotulos_listados(ability).sort).to eq(%w[ff_app_outro ff_avaliacao_outro])
    expect(ability.can?(:read, formulario("ff_app_pendente"))).to be(false)
  end

  it "nao da formulario nenhum ao professor sem pendencia nem avaliacao" do
    ability = Ability.new(vestir_perfil(perfil("professor sem professor vinculado")))

    expect(rotulos_listados(ability)).to be_empty
  end

  # Controle: a gestão lê todos, por uma regra só.
  it "da todos a coordenacao" do
    ability = Ability.new(vestir_perfil(perfil("coordenacao")))

    expect(rotulos_listados(ability).size).to eq(12)
  end
end

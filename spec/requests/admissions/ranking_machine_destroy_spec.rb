# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# RankingMachine has_many :ranking_processes, dependent: :destroy: excluir um
# seletor em uso apaga as linhas de processo de toda configuração que o usa.
RSpec.describe "Excluir seletor de ranking em uso", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_coordenacao)], "machine_destroy_coord@ic.uff.br", "Coord")
    @machine = FactoryBot.create(:ranking_machine, name: "AC")
    @config = FactoryBot.create(:ranking_config, name: "Seleção", default_machine: @machine)
  end

  it "exclui o seletor que nenhuma configuração usa" do
    unused = FactoryBot.create(:ranking_machine, name: "Livre")
    delete ranking_machine_path(unused), xhr: true
    expect(Admissions::RankingMachine.exists?(unused.id)).to be false
  end

  it "recusa excluir o seletor em uso e mantém os processos", pending: "issue #756" do
    delete ranking_machine_path(@machine), xhr: true
    expect(Admissions::RankingMachine.exists?(@machine.id)).to be true
    expect(@config.ranking_processes.reload.count).to eq(1)
  end
end

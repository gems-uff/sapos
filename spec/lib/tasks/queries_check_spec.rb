# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O queries:check roda nas instalacoes antes e depois de migration que mexa em
# coluna, e nada o invocava (#720). A consulta quebrada e gravada com
# save(validate: false), como fica no banco quando a coluna some depois.
RSpec.describe "queries:check", type: :task do
  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    Rake::Task["queries:check"].reenable
    @valida = FactoryBot.create(:query, name: "Consulta valida", sql: "SELECT id FROM users")
  end

  def roda
    saida = StringIO.new
    original = $stdout
    $stdout = saida
    codigo = nil
    begin
      Rake::Task["queries:check"].invoke
    rescue SystemExit => e
      codigo = e.status
    ensure
      $stdout = original
    end
    [saida.string, codigo]
  end

  it "diz que todas executaram e termina sem codigo de erro" do
    saida, codigo = roda

    expect(codigo).to be_nil
    expect(saida).to include("consultas gravadas: 1")
    expect(saida).to include("todas executaram contra o esquema atual.")
  end

  it "lista a consulta quebrada com o erro e sai com codigo 1" do
    quebrada = Query.new(name: "Consulta velha", sql: "SELECT coluna_que_sumiu FROM users")
    quebrada.save(validate: false)

    saida, codigo = roda

    expect(codigo).to eq(1)
    expect(saida).to include("consultas gravadas: 2")
    expect(saida).to include("1 nao executaram:")
    expect(saida).to include("[#{quebrada.id}] Consulta velha")
    expect(saida).to include("coluna_que_sumiu")
    expect(saida).not_to include("Consulta valida")
  end

  it "nao conta como quebrada a consulta invalida por outro motivo que nao o SQL" do
    sem_nome = Query.new(name: "", sql: "SELECT id FROM users")
    sem_nome.save(validate: false)

    saida, codigo = roda

    expect(codigo).to be_nil
    expect(saida).to include("consultas gravadas: 2")
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Os ramos ERB e Ruby do CodeEvaluator e do ErbFormatter estavam sem cobertura
# (#720). Nao se criam mais templates nesses formatos, mas os gravados antes da
# trava ainda rodam -- campo CODE/EMAIL de formulario, assercao, notificacao --
# e passam por aqui ate a #684 tira-los.
RSpec.describe CodeEvaluator, "nos ramos ERB e Ruby" do
  describe ".create_formatter" do
    it "devolve o ErbFormatter para ERB, sem converter os dados em drops" do
      formatter = CodeEvaluator.create_formatter({ nome: "Ana" }, "ERB")

      expect(formatter).to be_a(ErbFormatter)
      expect(formatter.format("<%= var(:nome) %>")).to eq("Ana")
    end
  end

  describe ".evaluate_code" do
    it "avalia Ruby com os dados como variaveis locais" do
      expect(CodeEvaluator.evaluate_code("x + y", { x: 2, y: 3 }, "Ruby")).to eq(5)
    end

    # O binding e o do proprio metodo: um dado com o nome de uma das locais
    # dele (b, code, bindings) a sobrescreve antes do eval.
    it "quebra quando um dado se chama b, como a local que guarda o binding" do
      expect { CodeEvaluator.evaluate_code("1", { b: 3 }, "Ruby") }
        .to raise_error(NoMethodError, /private method 'eval' called for an instance of Integer/)
    end

    it "renderiza ERB com os dados" do
      expect(CodeEvaluator.evaluate_code("Ola <%= var(:nome) %>", { nome: "Ana" }, "ERB"))
        .to eq("Ola Ana")
    end
  end
end

RSpec.describe ErbFormatter, "nos cantos" do
  it "localiza uma data pelo formato padrao" do
    data = Date.new(2026, 3, 10)

    expect(ErbFormatter.new({ d: data }).format("<%= localize(var(:d)) %>"))
      .to eq(I18n.localize(data.to_time, format: :default))
  end

  it "localiza uma data escrita como texto, pelo atalho l com formato" do
    expect(ErbFormatter.new({}).format("<%= l('2026-03-10', :short) %>"))
      .to eq(I18n.localize(Time.parse("2026-03-10"), format: :short))
  end

  it "escapa os valores de um Hash e mantem as chaves" do
    formatter = ErbFormatter.new({ h: { "<k>" => "<v>" } })

    expect(formatter.format("<%= var(:h).to_a.flatten.join('|') %>", escape_data: :html))
      .to eq("<k>|&lt;v&gt;")
  end

  it "devolve sem escapar o dado que nao e texto" do
    formatter = ErbFormatter.new({ n: 7, columns: ["nota"], rows: [[7.5]] })

    expect(formatter.format("<%= var(:n) + 1 %>;<%= records.first['nota'] %>", escape_data: :html))
      .to eq("8;7.5")
  end
end

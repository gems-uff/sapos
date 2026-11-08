# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

# Os templates que cada instalacao grava pela tela -- declaracoes,
# notificacoes, codigo e e-mail dos campos de consolidacao -- nao estao no
# repositorio, e a suite nunca os renderiza. Um upgrade do liquid que mude o
# que eles produzem passaria verde.
#
# Este arquivo reproduz as formas desses templates, medidas nos bancos das
# instalacoes sem copiar texto, nome de coluna nem dado (#719): o vocabulario
# (tags, filtros, operadores, formatos) e o formato de cada expressao. Os
# nomes e os valores daqui sao sinteticos. Cada grupo monta os bindings pelo
# mesmo caminho do modelo que renderiza aquele tipo de template.
#
# Quando uma forma nova aparecer nas instalacoes, ela entra aqui; o que este
# arquivo nao tem, a suite nao protege.
RSpec.describe LiquidFormatter, type: :model do
  # Os resultados de consulta chegam com tipos diferentes conforme o banco: em
  # SQLite data e numero vem como texto, em MariaDB como Date, Integer e
  # BigDecimal. Os exemplos que dependem disso rodam com os dois.
  def colunas_e_linhas(colunas, linhas)
    { columns: colunas, rows: linhas }
  end

  describe "uma declaracao (Assertion#format_text)" do
    # Mesmo binding do modelo: as linhas, as colunas e, como variavel solta,
    # cada coluna cujo valor e o mesmo em todas as linhas.
    def declaracao(template, colunas, linhas, escape: :pdf)
      bindings = colunas_e_linhas(colunas, linhas)
      colunas.each_with_index do |coluna, i|
        valores = linhas.map { |linha| linha[i] }
        bindings[coluna] = valores.first if valores.uniq.size == 1
      end
      CodeEvaluator.create_formatter(bindings, "Liquid").format(template, escape_data: escape)
    end

    {
      "texto (SQLite)" => "2026-03-01",
      "Date (MariaDB)" => Date.new(2026, 3, 1)
    }.each do |origem, data|
      it "localiza a data de cada registro nos formatos usados, com data em #{origem}" do
        template = "{%- for r in records -%}" \
          "{{ r.inicio | localize: 'defaultdate' }}|{{ r.inicio | localize: 'longdate' }}|" \
          "{{ r.inicio | localize: 'monthyear' }}|{{ r.inicio | localize: 'monthyear2' }}" \
          "{%- endfor -%}"

        expect(declaracao(template, ["inicio"], [[data]]))
          .to eq("01-03-2026|01 de Março de 2026|Março-2026|Março/2026")
      end
    end

    it "localiza uma coluna comum a todas as linhas, lida como variavel solta" do
      expect(declaracao("{{ emissao | localize: 'longdate' }}", ["emissao", "x"],
                        [["2026-03-01", 1], ["2026-03-01", 2]]))
        .to eq("01 de Março de 2026")
    end

    # O assign guarda o valor ja escapado (#743). Cada forma tem o exemplo com
    # o escape da declaracao, pending, e o controle sem escape, que prova que
    # o cenario monta e que so o escape muda o resultado.
    context "com sinalizador ligado dentro do laco e testado depois" do
      template = "{%- assign achou = false -%}" \
        "{%- for r in records -%}{%- if r.situacao == 'Aprovado' -%}{%- assign achou = true -%}{%- endif -%}{%- endfor -%}" \
        "{%- if achou -%}sim{%- else -%}nao{%- endif -%}"

      it "fica verdadeiro so quando um registro o liga", pending: "issue #743" do
        expect(declaracao(template, ["situacao"], [["Reprovado"], ["Aprovado"]])).to eq("sim")
        expect(declaracao(template, ["situacao"], [["Reprovado"], ["Cancelado"]])).to eq("nao")
      end

      it "fica verdadeiro so quando um registro o liga, sem escape (controle)" do
        expect(declaracao(template, ["situacao"], [["Reprovado"], ["Aprovado"]], escape: nil)).to eq("sim")
        expect(declaracao(template, ["situacao"], [["Reprovado"], ["Cancelado"]], escape: nil)).to eq("nao")
      end
    end

    context "com numero acumulado no laco e comparado depois" do
      template = "{%- assign total = 0 -%}" \
        "{%- for r in records -%}{%- assign total = total | plus: r.creditos -%}{%- endfor -%}" \
        "{%- if total > 5 -%}maior{%- else -%}menor{%- endif -%}"

      it "compara o total com >", pending: "issue #743" do
        expect(declaracao(template, ["creditos"], [[4], [6]])).to eq("maior")
      end

      it "compara o total com >, sem escape (controle)" do
        expect(declaracao(template, ["creditos"], [[4], [6]], escape: nil)).to eq("maior")
      end
    end

    context "com texto atribuido e impresso depois" do
      it "escapa uma vez, como a impressao direta", pending: "issue #743" do
        expect(declaracao("{%- assign x = records[0].nome -%}{{ x }}", ["nome"], [["P&D <x>"]]))
          .to eq(declaracao("{{ records[0].nome }}", ["nome"], [["P&D <x>"]]))
      end

      it "sai igual a impressao direta, sem escape (controle)" do
        expect(declaracao("{%- assign x = records[0].nome -%}{{ x }}", ["nome"], [["P&D <x>"]], escape: nil))
          .to eq("P&D <x>")
      end
    end

    it "combina igualdade e diferenca com and, comparando atributo com variavel e com texto" do
      template = "{%- assign alvo = 'Mestrado' -%}" \
        "{%- for r in records -%}" \
        "{%- if r.nivel == alvo and r.situacao != 'Cancelado' -%}{{ r.nome }};{%- endif -%}" \
        "{%- endfor -%}"
      linhas = [["A", "Mestrado", "Ativo"], ["B", "Mestrado", "Cancelado"],
                ["C", "Doutorado", "Ativo"]]

      expect(declaracao(template, ["nome", "nivel", "situacao"], linhas)).to eq("A;")
    end

    {
      "texto (SQLite)" => ["4", "6"],
      "Integer (MariaDB)" => [4, 6]
    }.each do |origem, creditos|
      it "acumula uma coluna com plus dentro do laco, com numero em #{origem}" do
        template = "{%- assign total = 0 -%}" \
          "{%- for r in records -%}{%- assign total = total | plus: r.creditos -%}{%- endfor -%}" \
          "{{ total }}"

        expect(declaracao(template, ["creditos"], creditos.map { |c| [c] })).to eq("10")
      end
    end

    it "divide uma coluna inteira e uma decimal, cada uma com a sua divisao" do
      template = "{%- for r in records -%}{{ r.horas | divided_by: 2 }}|{{ r.media | divided_by: 2 }}{%- endfor -%}"

      expect(declaracao(template, ["horas", "media"], [[7, BigDecimal("7.0")]])).to eq("3|3.5")
      expect(declaracao(template, ["horas", "media"], [["7", "7.0"]])).to eq("3|3.5")
    end

    it "escreve a data em ingles pelo filtro date, dentro e fora do bloco de idioma" do
      template = "{% language en %}{{ d | date: '%B %d, %Y' }}{% endlanguage %}|" \
        "{% language pt-BR %}{{ d | localize: 'longdate' }}{% endlanguage %}"

      expect(declaracao(template, ["d"], [["2026-03-01"]]))
        .to eq("March 01, 2026|01 de Março de 2026")
      expect(I18n.locale).to eq(:"pt-BR")
    end
  end

  describe "o codigo de um campo de consolidacao (FilledForm#consolidate)" do
    # O modelo avalia o codigo com os campos ja preenchidos e as notas das
    # comissoes; o resultado e texto, convertido depois pelo tipo do campo.
    def consolidar(codigo, fields: {}, committees: [], extra: {})
      vars = { fields: fields, committees: committees }.merge(extra)
      CodeEvaluator.evaluate_code(codigo, vars, "Liquid", Admissions::FilledForm::CONSOLIDATE_DROPS)
    end

    it "pondera notas lidas por colchete, e a divisao segue o tipo do valor" do
      codigo = "{%- assign a = fields['Nota A'] | times: 2 -%}{%- assign b = fields['Nota B'] -%}" \
        "{{ a | plus: b | divided_by: 3 }}"

      expect(consolidar(codigo, fields: { "Nota A" => 8.0, "Nota B" => 5.0 })).to eq("7.0")
      expect(consolidar(codigo, fields: { "Nota A" => 8, "Nota B" => 6 })).to eq("7")
      expect(consolidar(codigo, fields: { "Nota A" => "8", "Nota B" => "6" })).to eq("7")
      expect(consolidar(codigo, fields: { "Nota A" => "8.5", "Nota B" => "6" })).to eq("7.666666666666667")
    end

    it "calcula numa expressao so, com arredondamento no fim" do
      codigo = "{{ fields['A'] | times: 3 | plus: fields['B'] | plus: fields['C'] | divided_by: 5 | round: 1 }}"

      expect(consolidar(codigo, fields: { "A" => 9.0, "B" => 7.5, "C" => 6.0 })).to eq("8.1")
    end

    it "soma varios campos em sequencia" do
      codigo = "{%- assign x = fields['A'] -%}{%- assign y = fields['B'] -%}{%- assign z = fields['C'] -%}" \
        "{%- assign s = x | plus: y | plus: z -%}{{ s | plus: 1 | divided_by: 2 | round: 2 }}"

      expect(consolidar(codigo, fields: { "A" => 1.5, "B" => 2.0, "C" => 3.0 })).to eq("3.75")
    end

    it "tira a media das comissoes por uma coluna, com e sem arredondamento" do
      committees = [{ "Nota" => 7.0 }, { "Nota" => 8.0 }, { "Nota" => 8.5 }]

      expect(consolidar("{{ committees | avg: 'Nota' }}", committees: committees))
        .to eq("7.833333333333333")
      expect(consolidar("{{ committees | avg: 'Nota' | round: 2 }}", committees: committees))
        .to eq("7.83")
    end

    it "monta um texto com append e o desmonta com split, indexando por variavel" do
      codigo = "{%- assign t = fields['Linha'] | append: ' - ' | append: fields['Orientador'] " \
        "| append: ' / ' | append: fields['Ano'] -%}" \
        "{%- assign partes = fields['Data'] | split: '/' -%}{%- assign i = 1 -%}" \
        "{%- assign mes = partes[i] -%}{{ t }}|{{ mes }}"

      fields = { "Linha" => "L1", "Orientador" => "O1", "Ano" => "2026", "Data" => "15/03/2026" }
      expect(consolidar(codigo, fields: fields)).to eq("L1 - O1 / 2026|03")
    end

    it "conta os dias entre duas datas pela diferenca de date: '%s'" do
      codigo = "{%- assign fim = prazo.fim | date: '%s' -%}{%- assign ini = fields['Envio'] | date: '%s' -%}" \
        "{%- assign dias = fim | minus: ini | divided_by: 86400 -%}{{ dias }}"

      expect(consolidar(codigo, fields: { "Envio" => "2026-03-01" },
                                extra: { "prazo" => { "fim" => "2026-03-31" } })).to eq("30")
    end
  end

  describe "o e-mail de um campo de consolidacao" do
    it "le os atributos e os campos pelo formatter do modelo" do
      formatter = CodeEvaluator.create_formatter(
        { fields: { "Resultado" => "Aprovado" }, committees: [] },
        "Liquid", Admissions::FilledForm::CONSOLIDATE_DROPS
      )

      expect(formatter.format("Resultado: {{ fields['Resultado'] }}", escape_data: :html))
        .to eq("Resultado: Aprovado")
    end
  end

  describe "uma notificacao (Notification#execute)" do
    def notificacao(template, colunas, linhas, params = {}, escape: :html)
      bindings = colunas_e_linhas(colunas, linhas).merge(params)
      CodeEvaluator.create_formatter(bindings, "Liquid", Notification::NOTIFICATION_DROPS)
        .format(template, escape_data: escape)
    end

    it "manda para os e-mails dos papeis de coordenacao e de secretaria" do
      create_confirmed_user([FactoryBot.create(:role_coordenacao)], "coord@ic.uff.br", "Coord")
      create_confirmed_user([FactoryBot.create(:role_secretaria)], "sec@ic.uff.br", "Sec")

      expect(notificacao("{% emails Coordenação %}", [], [])).to eq("coord@ic.uff.br")
      expect(notificacao("{% emails Secretaria %}", [], [])).to eq("sec@ic.uff.br")
    end

    it "lista os registros com a data localizada e o espaco controlado" do
      template = "<ul>\n{%- for r in records %}\n  <li>{{ r.nome }}: {{ r.prazo | localize: 'monthyear' }}</li>\n{%- endfor %}\n</ul>"

      expect(notificacao(template, ["nome", "prazo"], [["A", "2026-03-01"], ["B", Date.new(2026, 4, 1)]]))
        .to eq("<ul>\n  <li>A: Março-2026</li>\n  <li>B: Abril-2026</li>\n</ul>")
    end

    it "localiza um parametro da notificacao, que chega como valor solto" do
      expect(notificacao("{{ data_consulta | localize: 'defaultdate' }}", [], [],
                         { data_consulta: Date.new(2026, 3, 1) }))
        .to eq("01-03-2026")
    end

    # O capture guarda a saida do bloco ja escapada, e o {{ }} escapa de novo
    # (#743).
    context "com texto guardado por capture e impresso depois" do
      template = "{%- capture x -%}{{ records[0].nome }}{%- endcapture -%}{{ x }}"

      it "escapa uma vez, como a impressao direta", pending: "issue #743" do
        expect(notificacao(template, ["nome"], [["P&D <x>"]]))
          .to eq(notificacao("{{ records[0].nome }}", ["nome"], [["P&D <x>"]]))
      end

      it "sai igual a impressao direta, sem escape (controle)" do
        expect(notificacao(template, ["nome"], [["P&D <x>"]], escape: nil)).to eq("P&D <x>")
      end
    end
  end
end

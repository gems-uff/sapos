# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Testes de caracterização (golden-master) para as saídas binárias — issue #636.
#
# A suíte de features só confere o NOME do arquivo baixado, então uma mudança de
# gem (prawn, caxlsx) pode alterar o conteúdo do relatório sem quebrar teste
# algum. Estes helpers capturam a saída uma vez e comparam nas rodadas seguintes.
#
# Comparar bytes não funciona, e não é só por causa do relógio: o PDF assinado
# embute um QR com nonce, que muda a cada geração. Por isso a comparação é
# SEMÂNTICA — o texto que o PDF apresenta e a matriz de células da planilha. O QR
# é imagem, então simplesmente não aparece na extração de texto; e o timestamp do
# container XLSX não é lido.
#
# O preço é conhecido: mudança puramente de layout (largura de coluna, quebra de
# página que não reordena o texto) passa despercebida. É o que a homologação
# continua cobrindo.
#
# Para (re)gerar os baselines depois de uma mudança intencional:
#
#   GOLDEN=overwrite bundle exec rspec spec/requests/goldens
#
# e confira o diff dos arquivos em spec/goldens/ antes de aceitar.
module GoldenMaster
  GOLDEN_DIR = Rails.root.join("spec", "goldens")

  # Campos que variam a cada execução e não dizem nada sobre regressão.
  # Instante fixo em que os relatórios são gerados. Congelar o relógio é mais
  # rigoroso do que mascarar data e hora: a data renderizada entra no baseline,
  # então uma mudança de FORMATO ("15/06/2021" virando "2021-06-15") é detectada
  # em vez de escondida atrás de uma máscara. Foi por isso que as máscaras que
  # existiam aqui saíram.
  #
  # 15/06/2021 é terça-feira, e cai dentro da vigência da bolsa do cenário
  # (03/2020 a 02/2022), então os relatórios têm o que mostrar.
  FROZEN_AT = Time.utc(2021, 6, 15, 13, 30, 0)

  def expect_matches_golden(name, content, format:)
    actual = golden_representation(content, format)
    path = GOLDEN_DIR.join("#{name}.txt")

    if ENV["GOLDEN"] == "overwrite" || !path.exist?
      FileUtils.mkdir_p(path.dirname)
      path.write(actual)
      skip "baseline #{name} gravado; rode de novo para comparar" unless ENV["GOLDEN"]
      return
    end

    expect(actual).to eq(path.read),
      "a saída divergiu do baseline #{path.relative_path_from(Rails.root)}.\n" \
      "Se a mudança for intencional: GOLDEN=overwrite bundle exec rspec <arquivo>"
  end

  def golden_representation(content, format)
    case format
    when :pdf  then pdf_representation(content)
    when :xlsx then xlsx_representation(content)
    else raise ArgumentError, "sem normalizador para #{format.inspect}"
    end
  end

  # Texto por página, na ordem em que o prawn o colocou.
  def pdf_representation(content)
    reader = PDF::Reader.new(StringIO.new(content))
    reader.pages.map.with_index(1) do |page, number|
      "── página #{number} ──\n#{normalize(page.text)}"
    end.join("\n")
  end

  # XLSX é um zip de XML. Lemos as células direto, sem roo: o rubyzip e o
  # nokogiri já estão no bundle, e assim não se lê mtime de entrada do zip nem
  # o docProps/core.xml, que carregam timestamp.
  def xlsx_representation(content)
    sheets = []
    Zip::File.open_buffer(StringIO.new(content)) do |zip|
      shared = shared_strings(zip)
      zip.entries.map(&:name)
         .select { |n| n.match?(%r{\Axl/worksheets/sheet\d+\.xml\z}) }
         .sort
         .each { |name| sheets << "── #{name} ──\n#{sheet_cells(zip.read(name), shared)}" }
    end
    sheets.join("\n")
  end

  private
    def shared_strings(zip)
      entry = zip.find_entry("xl/sharedStrings.xml")
      return [] if entry.nil?

      Nokogiri::XML(zip.read("xl/sharedStrings.xml"))
        .css("si").map { |si| si.css("t").map(&:text).join }
    end

    def sheet_cells(xml, shared)
      Nokogiri::XML(xml).css("sheetData row").filter_map do |row|
        cells = row.css("c").filter_map do |cell|
          value =
            case cell["t"]
            when "s"         then shared[cell.css("v").text.to_i].to_s
            when "inlineStr" then cell.css("is t").map(&:text).join
            else cell.css("v").text
            end
          next if value.strip.empty?
          "#{cell['r']}=#{normalize(value)}"
        end
        cells.join(" | ") unless cells.empty?
      end.join("\n")
    end

    # Só espaço em branco: o relógio congelado dispensa mascarar data e hora.
    def normalize(text)
      text.gsub(/[ \t]+/, " ").gsub(/[ \t]+$/, "").strip
    end
end

RSpec.configure do |config|
  config.include GoldenMaster, type: :request
  config.include ActiveSupport::Testing::TimeHelpers, type: :request
end

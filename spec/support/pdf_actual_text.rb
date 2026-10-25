# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Leitura do ActualText (config/initializers/prawn_actual_text.rb) nos PDFs da
# suíte. O page.text do pdf-reader não serve para isso, em nenhum dos dois
# sentidos:
#
# - ele troca o glifo desenhado pela frase falada, então o texto que o vidente
#   lê some da extração;
# - ele pendura a frase inteira no primeiro glifo da célula e a encaixa por
#   posição, então a frase sai embaralhada com a célula vizinha conforme a
#   coluna (Quinta e Sexta, no quadro de horários) e o tamanho do nome.
#
# Por isso as duas coisas se leem em separado: a frase direto dos operadores do
# conteúdo da página, e o desenho com a chave renomeada para que o pdf-reader a
# ignore.
module PdfActualText
  SPAN = /\/ActualText <(\h*)>/

  extend self

  # Frases de ActualText de cada página, na ordem em que foram desenhadas.
  def actual_texts(content)
    PDF::Reader.new(StringIO.new(content)).pages.map do |page|
      page.raw_content.scan(SPAN).map { |(hex)| decode(hex) }
    end
  end

  # O mesmo PDF sem ActualText, para extrair o que está desenhado. A chave
  # trocada tem o mesmo comprimento, então a tabela xref continua valendo; isso
  # pede PDF sem compressão, que é como o Prawn gera.
  def without_actual_text(content)
    content.b.gsub("/ActualText", "/ActualTexX")
  end

  private
    def decode(hex)
      [hex].pack("H*").force_encoding(Encoding::UTF_16BE)
        .encode(Encoding::UTF_8).delete_prefix("﻿")
    end
end

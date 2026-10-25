# frozen_string_literal: true

# Acessibilidade do quadro de horários (Issue #224). O Prawn não gera PDF
# marcado (tagged PDF / PDF/UA) — é limitação conhecida da gem. Mas o padrão PDF
# tem o atributo ActualText, que envolve um trecho do conteúdo e diz "para
# extração e leitura, este trecho vale por este texto"; funciona em PDF sem
# árvore de tags e é honrado por leitores de tela como NVDA/JAWS no Adobe Reader.
#
# Este patch dá a cada célula de texto de tabela um atributo opcional
# `actual_text`. Quando presente, o desenho da célula é envolvido pelos
# operadores de conteúdo marcado (BDC/EMC), fazendo o leitor de tela anunciar a
# frase falada no lugar do texto visível — na célula do quadro onde o vidente vê
# "11-13", o cego ouve "Terça, 11h às 13h, Sala: 208". Sem o atributo, o desenho
# é idêntico ao de antes, então nenhum outro relatório é afetado.
#
# Depende de interno de duas gems, logo suspeito num upgrade de qualquer uma:
# do prawn-table, o `draw_content` privado de Prawn::Table::Cell::Text e o @pdf
# da célula; do Prawn, o `renderer`. `prepend`, e não `alias_method`, para que
# carregar o arquivo de novo não encadeie o método nele mesmo.
#
# A frase por célula é montada em
# ClassScheduleHelperConcern#class_schedule_spoken_allocation e aplicada em
# ClassSchedulesPdfHelper#apply_class_schedule_actual_text.

require "prawn"
require "prawn/table"

module PrawnActualText
  attr_accessor :actual_text

  def draw_content
    return super if actual_text.blank?

    # ActualText em conteúdo marcado é recurso do PDF 1.5; o Prawn declara 1.3
    # e só sobe a versão quando ele mesmo usa algo mais novo.
    @pdf.renderer.min_version(1.5)
    # pdf_object escreve a string em UTF-16BE com BOM, como o padrão pede para
    # texto com acento.
    @pdf.renderer.add_content(
      "/Span #{PDF::Core.pdf_object({ ActualText: actual_text })} BDC"
    )
    super
    @pdf.renderer.add_content("EMC")
  end
end

Prawn::Table::Cell::Text.prepend(PrawnActualText)

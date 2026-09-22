# frozen_string_literal: true

# Acessibilidade do quadro de horários (Issue #224). O Prawn não gera PDF
# marcado (tagged PDF / PDF/UA) — é limitação conhecida da gem. Mas o padrão PDF
# tem o atributo ActualText, que envolve um trecho do conteúdo e diz "para
# extração e leitura, este trecho vale por este texto"; funciona em PDF sem
# árvore de tags e é honrado por leitores de tela como NVDA/JAWS no Adobe Reader.
#
# Este patch dá a cada célula de tabela um atributo opcional `actual_text`.
# Quando presente, o desenho da célula é envolvido pelos operadores de conteúdo
# marcado (BDC/EMC), fazendo o leitor de tela anunciar a frase falada no lugar
# do texto visível — na célula do quadro onde o vidente vê "11-13", o cego ouve
# "Terça, 11h às 13h, Sala: 208". Sem o atributo, o desenho é idêntico ao de
# antes, então nenhum outro relatório é afetado.
#
# É monkey-patch de interno do prawn-table (reabre Cell), logo suspeito num
# upgrade do Prawn. A frase por célula é montada em
# ClassScheduleHelperConcern#class_schedule_spoken_allocation e aplicada em
# ClassSchedulesPdfHelper#apply_class_schedule_actual_text.

require "prawn"
require "prawn/table"

module PrawnActualText
  module_function

  # ActualText é uma string PDF; com acento, precisa ser UTF-16BE com BOM
  # (U+FEFF) escrita como string hexadecimal: <FEFF0054...>. O BOM é montado por
  # bytes para não deixar caractere invisível no fonte.
  def pdf_string(text)
    bom = [0xFE, 0xFF].pack("C*")
    "<#{(bom + text.encode("UTF-16BE").b).unpack1("H*").upcase}>"
  end
end

# class_eval em vez de reabrir com `class`/`module`: Cell é uma classe no
# prawn-table (não um módulo), e reabrir com a keyword errada faz o Ruby
# recusar a redeclaração ("Cell is not a module"). class_eval só navega pela
# constante existente, sem redeclarar o tipo.
Prawn::Table::Cell::Text.class_eval do
  attr_accessor :actual_text

  alias_method :draw_content_without_actual_text, :draw_content

  def draw_content
    return draw_content_without_actual_text if actual_text.blank?

    @pdf.renderer.add_content(
      "/Span <</ActualText #{PrawnActualText.pdf_string(actual_text)}>> BDC"
    )
    draw_content_without_actual_text
    @pdf.renderer.add_content("EMC")
  end
end

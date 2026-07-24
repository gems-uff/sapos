#!/usr/bin/env ruby
# frozen_string_literal: true

# Compara duas capturas binarias feitas por capture_binary.rb.
#
# Uso: ruby compare_binary.rb <dir_antes> <dir_depois>
#
# NAO compara os bytes do arquivo: PDF embute data de criacao, entao o mesmo
# relatorio gerado duas vezes ja tem hash diferente. A comparacao e feita nos
# artefatos derivados:
#   PDF  -> PNG por pagina, contagem de pixels que diferem + bounding box
#   XLSX -> XML descompactado, comparado como texto
#
# Requer: ImageMagick (magick).
#
# Duas armadilhas ja custaram caro aqui, ambas devolvendo "nenhuma diferenca"
# para paginas que sabidamente diferiam:
#   1. `magick compare -metric AE` imprime notacao cientifica ("4.53718e+07");
#      ler o inicio com /\A\d+/ devolvia "4". Alem disso, em PNG paletizado o AE
#      diverge de uma contagem real de pixel. Trocado por um composite de
#      diferenca + threshold, que conta pixel de verdade e ainda da a bbox.
#   2. Os PNGs sao PaletteAlpha; sem achatar sobre fundo branco antes do
#      composite, a diferenca sai zero. Por isso o -background white -flatten.
# A checagem de sanidade no fim guarda contra a proxima variante do mesmo erro.

require "json"

A = ARGV[0] or abort "uso: ruby compare_binary.rb <dir_antes> <dir_depois>"
B = ARGV[1] or abort "uso: ruby compare_binary.rb <dir_antes> <dir_depois>"

def load_dir(dir)
  JSON.parse(File.read(File.join(dir, "results_binary.json")))
      .each_with_object({}) { |r, acc| acc[r["route"]] = r }
end

def slug(route)
  route.sub(%r{\A/}, "").gsub(%r{[/.]}, "_")
end

# Campos que mudam a cada geracao e nao indicam regressao.
VOLATILE_XML = %r{docProps/core\.xml\z}

# Conta os pixels que diferem entre dois PNGs e devolve tambem onde diferem.
# Achata sobre branco (os PNGs sao PaletteAlpha) e mede pela media do composite
# de diferenca apos threshold -- nao pelo -metric AE, que engana em paletizado.
# Retorna [contagem, bbox] ou [nil, mensagem] quando o magick falha.
def diff_pixels(p1, p2)
  fmt = "%[fx:int(mean*w*h+0.5)] %@"
  out = `magick \\( "#{p1}" -background white -flatten \\) \\( "#{p2}" -background white -flatten \\) \
         -compose difference -composite -colorspace Gray -threshold 0 -format "#{fmt}" info: 2>&1`.strip
  m = out.match(/\A(\d+)\s+(\S+)/)
  return [nil, out[0, 80]] unless m # tamanhos diferentes, formato inesperado etc.
  [m[1].to_i, m[2]]
end

before = load_dir(A)
after  = load_dir(B)

puts "rotas comparadas: #{(before.keys & after.keys).size}"

# Para a checagem de sanidade no fim: quantas paginas de PDF foram comparadas e
# quantas diferiram. Como as duas capturas sao de dias diferentes, o rodape com
# a hora de geracao muda em toda pagina -- entao zero paginas alteradas nao e
# "sem regressao", e sinal de comparador quebrado.
total_pdf_pages = 0
changed_pdf_pages = 0

before.each do |route, x|
  y = after[route]
  unless y
    puts "\n== #{route}\n   AUSENTE na captura depois"
    next
  end

  problems = []
  problems << "status #{x["status"]} -> #{y["status"]}" if x["status"] != y["status"]
  problems << "tipo #{x["kind"]} -> #{y["kind"]}" if x["kind"] != y["kind"]
  problems << "artefatos #{x["artifacts"]} -> #{y["artifacts"]}" if x["artifacts"] != y["artifacts"]

  name = slug(route)
  dir_a = File.join(A, "pages", name)
  dir_b = File.join(B, "pages", name)

  if x["kind"] == "pdf" && Dir.exist?(dir_a) && Dir.exist?(dir_b)
    pages_a = Dir[File.join(dir_a, "*.png")].sort
    total_pdf_pages += pages_a.size
    changed = []
    pages_a.each do |pa|
      pb = File.join(dir_b, File.basename(pa))
      unless File.exist?(pb)
        changed << "#{File.basename(pa)}: ausente"
        next
      end
      count, info = diff_pixels(pa, pb)
      if count.nil?
        changed << "#{File.basename(pa)}: #{info}" # info e a mensagem de erro
      elsif count.positive?
        changed << "#{File.basename(pa)}: #{count} px em #{info}" # info e a bbox
      end
    end
    changed_pdf_pages += changed.size
    problems << "paginas alteradas: #{changed.size}/#{pages_a.size}" if changed.any?
    @detail = changed
  elsif x["kind"] == "xlsx" && Dir.exist?(dir_a) && Dir.exist?(dir_b)
    files_a = Dir[File.join(dir_a, "**", "*")].select { |f| File.file?(f) }
    changed = []
    files_a.each do |fa|
      rel = fa.sub("#{dir_a}/", "")
      next if rel =~ VOLATILE_XML
      fb = File.join(dir_b, rel)
      unless File.exist?(fb)
        changed << "#{rel}: ausente"
        next
      end
      changed << rel if File.binread(fa) != File.binread(fb)
    end
    problems << "arquivos internos alterados: #{changed.size}/#{files_a.size}" if changed.any?
    @detail = changed
  else
    @detail = []
  end

  next if problems.empty?

  puts "\n== #{route}"
  problems.each { |p| puts "   #{p}" }
  @detail.first(10).each { |d| puts "      #{d}" }
  puts "      (+#{@detail.size - 10} outros)" if @detail.size > 10
end

puts "\nSem saida acima de uma rota = nenhuma diferenca nela."
puts "A contagem vem com a bounding box da diferenca. Rodape estreito repetido em"
puts "toda pagina (poucas centenas de px, mesma faixa) e a hora de geracao; area"
puts "larga fora do rodape, ou so em algumas paginas, merece inspecao visual em"
puts "pages/<rota>/p-XXX.png dos dois lados."

# VERIFICAR O PROPRIO INSTRUMENTO: um comparador quebrado tambem devolve zero.
# Duas versoes anteriores deste script devolviam "sem diferenca" para PDFs que
# sabidamente diferiam (AE lido como inteiro; PaletteAlpha nao achatado). Como as
# capturas sao de execucoes diferentes, o rodape com a hora de geracao muda em
# quase toda pagina -- zero aqui e o instrumento, nao o sistema.
if total_pdf_pages.positive?
  puts "\n[sanidade] paginas de PDF alteradas: #{changed_pdf_pages}/#{total_pdf_pages}"
  if changed_pdf_pages.zero?
    puts "[sanidade] ATENCAO: nenhuma pagina de PDF diferiu. O rodape com a hora"
    puts "           de geracao deveria mudar em quase toda pagina. Zero sugere"
    puts "           comparador quebrado -- confira antes de concluir 'sem regressao'."
  end
end

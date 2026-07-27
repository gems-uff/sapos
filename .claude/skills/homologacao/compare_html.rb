#!/usr/bin/env ruby
# frozen_string_literal: true

# Compara duas capturas HTML feitas por capture_html.rb.
#
# Uso: ruby compare_html.rb <dir_antes> <dir_depois>
#
# O hash do texto e recalculado aqui, a partir do texto bruto guardado em txt/,
# e nao lido do results.json. Isso permite mudar a regra de normalizacao sem
# refazer as capturas.
#
# Compara tambem os screenshots pixel a pixel: texto igual nao garante tela
# igual -- asset que sumiu, CSS que quebrou e layout deslocado mudam o PNG sem
# mudar uma letra do texto. Requer ImageMagick (magick); sem ele, a comparacao
# de texto continua valendo e so a de pixel e pulada.

require "json"
require "digest"

A = ARGV[0] or abort "uso: ruby compare_html.rb <dir_antes> <dir_depois>"
B = ARGV[1] or abort "uso: ruby compare_html.rb <dir_antes> <dir_depois>"

# So o rodape de versao e neutralizado: ele muda entre as duas execucoes e, sem
# isso, TODA pagina apareceria alterada. Datas NAO sao normalizadas de proposito
# -- mudanca de formato de data e uma das regressoes que se procura.
def norm(text)
  text.gsub(/^Vers[aã]o\s+\S+\s*\|\s*Cr[ée]ditos$/, "Versao <VER> | Creditos")
end

def slug(route)
  s = route.sub(%r{\A/}, "").gsub("/", "_")
  s.empty? ? "root" : s
end

# Conta os pixels que diferem entre dois PNGs e devolve tambem onde diferem.
# Mesma medicao do compare_binary.rb: achata sobre branco (os PNGs sao
# PaletteAlpha, e sem achatar o composite de diferenca devolve bbox vazia numa
# pagina que mudou) e mede pela media do composite, nao pelo -metric AE.
# Retorna [contagem, bbox] ou [nil, mensagem] quando o magick falha.
def diff_pixels(p1, p2)
  fmt = "%[fx:int(mean*w*h+0.5)] %@"
  out = `magick \\( "#{p1}" -background white -flatten \\) \\( "#{p2}" -background white -flatten \\) \
         -compose difference -composite -colorspace Gray -threshold 0 -format "#{fmt}" info: 2>&1`.strip
  # A bbox de uma diferenca vazia e indefinida, e o magick avisa no stderr
  # ("geometry does not contain image") ANTES de imprimir "0 0x0+...". Ancorar
  # em \A faria toda pagina identica virar "falha ao medir" -- exatamente o
  # oposto do que aconteceu. Por isso o padrao e procurado em qualquer posicao,
  # e o stderr continua junto para que uma falha de verdade apareca na mensagem.
  m = out.match(/(\d+)\s+(\d+x\d+[-+]\d+[-+]\d+)/)
  return [nil, out[0, 80]] unless m
  [m[1].to_i, m[2]]
end

def dimensions(path)
  `magick identify -format "%wx%h" "#{path}" 2>/dev/null`.strip
end

def load_dir(dir)
  JSON.parse(File.read(File.join(dir, "results.json"))).each_with_object({}) do |r, acc|
    path = File.join(dir, "txt", "#{slug(r["route"])}.txt")
    raw = File.exist?(path) ? File.read(path) : ""
    r["raw"] = raw
    r["norm"] = norm(raw)
    r["sha"] = Digest::SHA256.hexdigest(r["norm"])[0, 16]
    r["raw_sha"] = Digest::SHA256.hexdigest(raw)[0, 16]
    acc[r["route"]] = r
  end
end

before = load_dir(A)
after  = load_dir(B)

only_before = before.keys - after.keys
only_after  = after.keys - before.keys
status_diff = []
signal_diff = []
text_diff   = []

before.each do |route, x|
  y = after[route] or next
  status_diff << [route, x["status"], y["status"]] if x["status"] != y["status"]
  if x["console_errors"] != y["console_errors"] ||
     x["broken_requests"] != y["broken_requests"] ||
     x["failed_requests"] != y["failed_requests"]
    signal_diff << [route,
                    "console #{x["console_errors"]}->#{y["console_errors"]} " \
                    "broken #{x["broken_requests"]}->#{y["broken_requests"]} " \
                    "failed #{x["failed_requests"]}->#{y["failed_requests"]}"]
  end
  text_diff << [route, x, y] if x["sha"] != y["sha"]
end

puts "rotas comparadas: #{(before.keys & after.keys).size}"
puts "so no antes: #{only_before.size}#{only_before.empty? ? "" : " -> #{only_before.join(", ")}"}"
puts "so no depois: #{only_after.size}#{only_after.empty? ? "" : " -> #{only_after.join(", ")}"}"

puts "\nstatus diferente: #{status_diff.size}"
status_diff.each { |r, s1, s2| puts "   #{r}: #{s1} -> #{s2}" }

puts "\nsinais de console/rede diferentes: #{signal_diff.size}"
signal_diff.each { |r, s| puts "   #{r}: #{s}" }

puts "\ntexto diferente: #{text_diff.size}"
text_diff.each do |route, x, y|
  la = x["norm"].lines.map(&:strip)
  lb = y["norm"].lines.map(&:strip)
  puts "   #{route}: linhas #{la.size}->#{lb.size} " \
       "so_no_antes=#{(la - lb).size} so_no_depois=#{(lb - la).size}"
end

# VERIFICAR O PROPRIO INSTRUMENTO: um comparador quebrado tambem devolve zero.
# Sem normalizar, o rodape de versao deve acusar quase todas as paginas. Se este
# numero vier zero junto com o de cima, desconfie da comparacao, nao do sistema.
raw_diff = before.count do |route, x|
  y = after[route]
  y && x["raw_sha"] != y["raw_sha"]
end
puts "\n[sanidade] paginas cujo texto bruto difere (sem normalizar): #{raw_diff}"
if raw_diff.zero?
  puts "[sanidade] ATENCAO: nem o texto bruto difere. Se as duas capturas sao de"
  puts "           versoes diferentes, o rodape de versao deveria acusar quase"
  puts "           toda pagina. Zero aqui sugere que os dois diretorios sao a"
  puts "           mesma captura -- confira antes de concluir 'sem regressao'."
end

# ---------------------------------------------------------------------------
# SCREENSHOTS
#
# Texto igual nao e tela igual: asset que sumiu, CSS que quebrou e layout
# deslocado nao mudam uma letra do texto visivel. Aqui a comparacao e de pixel.
#
# A string de versao aparece em TODA pagina, sempre na mesma posicao, entao ela
# sozinha ja faz toda pagina diferir. Em vez de neutraliza-la por coordenada
# fixa -- que muda com tema, zoom e resolucao --, as paginas sao AGRUPADAS pela
# bounding box da diferenca: a faixa da versao vira um grupo unico com quase
# todas as paginas dentro, e o que diverge por outro motivo sobra em grupo
# proprio. Nenhuma coordenada fica escrita no codigo.
# ---------------------------------------------------------------------------

puts "\n--- screenshots ---"

if `which magick 2>/dev/null`.strip.empty?
  puts "[png] magick nao encontrado; comparacao de pixel PULADA."
  puts "[png] Instale o ImageMagick para que esta secao valha alguma coisa --"
  puts "      sem ela, so o texto foi comparado."
  exit
end

png_missing = []
dim_diff    = []
png_failed  = []
by_bbox     = Hash.new { |h, k| h[k] = [] }
png_compared = 0

(before.keys & after.keys).sort.each do |route|
  pa = File.join(A, "png", "#{slug(route)}.png")
  pb = File.join(B, "png", "#{slug(route)}.png")
  unless File.exist?(pa) && File.exist?(pb)
    png_missing << route
    next
  end
  png_compared += 1

  # Screenshot e de pagina inteira: se a pagina cresceu, a altura muda. O
  # composite se guia pela primeira imagem, entao a sobra ficaria de fora da
  # comparacao -- por isso o descasamento e reportado, nao engolido.
  da = dimensions(pa)
  db = dimensions(pb)
  dim_diff << [route, da, db] if da != db && !da.empty? && !db.empty?

  count, bbox = diff_pixels(pa, pb)
  if count.nil?
    png_failed << [route, bbox]
  elsif count.positive?
    by_bbox[bbox] << [route, count]
  end
end

puts "[png] paginas comparadas: #{png_compared}"

unless png_missing.empty?
  puts "[png] sem PNG em um dos lados: #{png_missing.size}"
  png_missing.each { |r| puts "   #{r}" }
end

unless png_failed.empty?
  puts "[png] falha ao medir: #{png_failed.size}"
  png_failed.each { |r, msg| puts "   #{r}: #{msg}" }
end

unless dim_diff.empty?
  puts "[png] dimensoes diferentes: #{dim_diff.size} (a pagina mudou de tamanho)"
  dim_diff.each { |r, x, y| puts "   #{r}: #{x} -> #{y}" }
end

changed = by_bbox.values.sum(&:size)
puts "[png] paginas com diferenca de pixel: #{changed}"

# Grupo maior primeiro por AREA da bbox: o que merece inspecao visual e a
# diferenca ampla, e a faixa estreita e repetida (a versao) cai para o fim.
area = ->(bbox) { bbox =~ /\A(\d+)x(\d+)/ ? Regexp.last_match(1).to_i * Regexp.last_match(2).to_i : 0 }
by_bbox.sort_by { |bbox, rotas| [-area.call(bbox), -rotas.size] }.each do |bbox, rotas|
  amostra = rotas.first(3).map(&:first).join(", ")
  reticencias = rotas.size > 3 ? ", ..." : ""
  px = rotas.map(&:last).max
  puts format("   %4dx  %-24s ate %6d px   %s%s",
              rotas.size, bbox, px, amostra, reticencias)
end

# VERIFICAR O PROPRIO INSTRUMENTO, de novo: as duas capturas sao de versoes
# diferentes, e a string de versao esta em toda pagina. Zero pagina alterada
# aqui nao e "sem regressao visual", e comparador quebrado.
if png_compared.positive? && changed.zero?
  puts "[sanidade] ATENCAO: nenhum screenshot difere. A string de versao deveria"
  puts "           acusar quase toda pagina. Confira se os dois diretorios nao"
  puts "           sao a mesma captura antes de concluir 'sem regressao'."
end

#!/usr/bin/env ruby
# frozen_string_literal: true

# Compara duas capturas HTML feitas por capture_html.rb.
#
# Uso: ruby compare_html.rb <dir_antes> <dir_depois>
#
# O hash do texto e recalculado aqui, a partir do texto bruto guardado em txt/,
# e nao lido do results.json. Isso permite mudar a regra de normalizacao sem
# refazer as capturas.

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

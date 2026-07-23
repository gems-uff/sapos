#!/usr/bin/env ruby
# frozen_string_literal: true

# Compara duas capturas binarias feitas por capture_binary.rb.
#
# Uso: ruby compare_binary.rb <dir_antes> <dir_depois>
#
# NAO compara os bytes do arquivo: PDF embute data de criacao, entao o mesmo
# relatorio gerado duas vezes ja tem hash diferente. A comparacao e feita nos
# artefatos derivados:
#   PDF  -> PNG por pagina, comparados pixel a pixel (ImageMagick)
#   XLSX -> XML descompactado, comparado como texto
#
# Requer: ImageMagick (magick, compare).

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

def diff_pixels(p1, p2)
  out = `magick compare -metric AE "#{p1}" "#{p2}" null: 2>&1`.strip
  count = out[/\A\d+/]&.to_i
  return [nil, out] if count.nil? # tamanhos diferentes, formato inesperado etc.
  [count, nil]
end

before = load_dir(A)
after  = load_dir(B)

puts "rotas comparadas: #{(before.keys & after.keys).size}"

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
    changed = []
    pages_a.each do |pa|
      pb = File.join(dir_b, File.basename(pa))
      unless File.exist?(pb)
        changed << "#{File.basename(pa)}: ausente"
        next
      end
      count, err = diff_pixels(pa, pb)
      if err
        changed << "#{File.basename(pa)}: #{err[0, 60]}"
      elsif count.positive?
        changed << "#{File.basename(pa)}: #{count} px"
      end
    end
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
puts "Para PDF, diferenca de poucos pixels costuma ser antialiasing de fonte;"
puts "diferenca em faixa larga ou em muitas paginas merece inspecao visual em"
puts "pages/<rota>/p-XXX.png dos dois lados."

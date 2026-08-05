#!/usr/bin/env ruby
# frozen_string_literal: true

# Baixa as rotas que retornam binario (PDF/XLSX) e as prepara para comparacao.
# Faz login pelo Selenium apenas para obter o cookie de sessao; os downloads vao
# por HTTP direto, porque o Chrome renderizaria o PDF em vez de entrega-lo.
#
# PDF  -> convertido em PNG por pagina (ImageMagick), para diff de pixel.
# XLSX -> descompactado, porque e um zip de XML; o diff e feito no XML.
#
# Uso:
#   set -a; source ~/.sapos_staging_env; set +a
#   ruby capture_binary.rb <dir_saida> [arquivo_rotas]

require "selenium-webdriver"
require "net/http"
require "uri"
require "json"
require "fileutils"
require "digest"

def env!(name)
  v = ENV[name]
  abort "Variavel #{name} nao definida." if v.nil? || v.empty?
  v
end

BASE = env!("SAPOS_STAGING_URL").sub(%r{/\z}, "")
USER = env!("SAPOS_STAGING_USER")
PASS = env!("SAPOS_STAGING_PASS")

out_dir = ARGV[0] or abort "uso: ruby capture_binary.rb <dir_saida> [arquivo_rotas]"
routes_file = ARGV[1] || File.join(__dir__, "routes_binary.txt")

if !BASE.include?("staging") && !ARGV.include?("--force")
  abort "A URL (#{BASE}) nao contem 'staging'. Se for intencional, use --force."
end

routes = File.readlines(routes_file, chomp: true)
             .map(&:strip)
             .reject { |r| r.empty? || r.start_with?("#") }

FileUtils.mkdir_p(File.join(out_dir, "raw"))
FileUtils.mkdir_p(File.join(out_dir, "pages"))

def slug(route)
  route.sub(%r{\A/}, "").gsub(%r{[/.]}, "_")
end

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless=new")
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 60)

cookie_header = nil
begin
  driver.navigate.to("#{BASE}/users/sign_in")
  wait.until { driver.find_element(id: "user_email") }
  driver.find_element(id: "user_email").send_keys(USER)
  f = driver.find_element(id: "user_password")
  f.send_keys(PASS)
  f.submit
  begin
    wait.until { !driver.current_url.include?("sign_in") }
  rescue Selenium::WebDriver::Error::TimeoutError
    reason = (driver.find_element(id: "error_login").text rescue "(sem mensagem)")
    abort "Login recusado para #{USER}. Mensagem da aplicacao: #{reason}"
  end
  cookie_header = driver.manage.all_cookies
                        .map { |c| "#{c[:name]}=#{c[:value]}" }.join("; ")
  puts "login ok; sessao capturada"
ensure
  driver&.quit
end

results = []
routes.each_with_index do |route, i|
  started = Time.now
  uri = URI.parse("#{BASE}#{route}")
  res = nil
  error = nil
  begin
    # Segue redirecionamento: varias rotas de PDF respondem 302 para a variante
    # com tipo de assinatura.
    5.times do
      req = Net::HTTP::Get.new(uri)
      req["Cookie"] = cookie_header
      req["Accept"] = "*/*"
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.read_timeout = 300 # relatorios grandes passam de 2 min
        http.request(req)
      end
      break unless res.is_a?(Net::HTTPRedirection) && res["location"]
      uri = URI.join(uri, res["location"])
    end
  rescue StandardError => e
    # Uma rota lenta nao pode derrubar a coleta inteira.
    error = "#{e.class}: #{e.message.lines.first&.strip}"
  end
  elapsed = ((Time.now - started) * 1000).round

  if res.nil?
    results << { route: route, status: nil, ms: elapsed, error: error,
                 kind: nil, bytes: 0, artifacts: 0, sha: nil }
    puts format("[%2d/%2d] %-50s ERRO %s", i + 1, routes.size, route, error)
    next
  end

  name = slug(route)
  body = res.body.to_s
  ctype = res["content-type"].to_s
  ext = if ctype.include?("pdf") then "pdf"
        elsif ctype.include?("spreadsheet") || ctype.include?("xlsx") then "xlsx"
        else "bin"
        end
  path = File.join(out_dir, "raw", "#{name}.#{ext}")
  File.binwrite(path, body)

  pages = 0
  if ext == "pdf" && res.code == "200"
    dir = File.join(out_dir, "pages", name)
    FileUtils.mkdir_p(dir)
    # -density fixo garante que as duas execucoes rasterizem igual
    system("magick", "-density", "100", path, File.join(dir, "p-%03d.png"), out: File::NULL, err: File::NULL)
    pages = Dir[File.join(dir, "*.png")].size
  elsif ext == "xlsx" && res.code == "200"
    dir = File.join(out_dir, "pages", name)
    FileUtils.mkdir_p(dir)
    system("unzip", "-o", "-q", path, "-d", dir, out: File::NULL, err: File::NULL)
    pages = Dir[File.join(dir, "**", "*")].count { |f| File.file?(f) }
  end

  results << {
    route: route, status: res.code.to_i, ms: elapsed, content_type: ctype, final_url: uri.to_s,
    bytes: body.bytesize, kind: ext, artifacts: pages,
    sha: Digest::SHA256.hexdigest(body)[0, 16]
  }
  puts format("[%2d/%2d] %-50s %s %-5s %7d bytes  %s",
              i + 1, routes.size, route, res.code, ext, body.bytesize,
              pages.positive? ? "#{pages} artefatos" : "")
end

File.write(File.join(out_dir, "results_binary.json"), JSON.pretty_generate(results))
puts "\nsaida em #{out_dir}/ (raw/, pages/, results_binary.json)"

# frozen_string_literal: true
# Base compartilhada da homologação exploratória: sobe o Chrome, loga (lendo a
# senha da env var, como os scripts de captura) e oferece helpers de screenshot.
# NAO imprime a senha. Screenshots vao para EXPLORE_OUT (contêm dado real, então
# aponte para fora do repositório).
#
#   require_relative "explore_common"   # a partir de um script na mesma pasta

require "selenium-webdriver"
require "json"
require "fileutils"

BASE = (ENV["SAPOS_STAGING_URL"] || abort("defina SAPOS_STAGING_URL")).sub(%r{/\z}, "")
USER = ENV["SAPOS_STAGING_USER"] || abort("defina SAPOS_STAGING_USER")
PASS = ENV["SAPOS_STAGING_PASS"] || abort("defina SAPOS_STAGING_PASS")

# Sem default: um diretório fixo aqui apontaria para a captura de uma rodada
# antiga e misturaria as saídas de rodadas diferentes.
OUT = ENV["EXPLORE_OUT"] ||
  abort("defina EXPLORE_OUT com o diretório da rodada (fora do repositório)")
FileUtils.mkdir_p(OUT)

def build_driver
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1440,1600")
  options.add_argument("--hide-scrollbars")
  options.add_argument("--force-device-scale-factor=1")
  options.add_argument("--lang=pt-BR")
  options.add_option("goog:loggingPrefs", { browser: "ALL", performance: "ALL" })
  Selenium::WebDriver.for(:chrome, options: options)
end

def login(driver, wait)
  driver.navigate.to("#{BASE}/users/sign_in")
  wait.until { driver.find_element(id: "user_email") }
  driver.find_element(id: "user_email").send_keys(USER)
  field = driver.find_element(id: "user_password")
  field.send_keys(PASS)
  field.submit
  wait.until { !driver.current_url.include?("sign_in") }
  puts "login ok -> #{driver.current_url}"
end

# O papel ativo (actual_role) fica GRAVADO no usuario e atravessa execucoes: uma
# sonda que nao troca herda o que a ultima captura deixou. Como a captura do
# aluno costuma rodar por ultimo, a sonda seguinte navega como aluno e nao acha
# link de edicao nenhum -- e o sintoma parece "a tela sumiu", nao "papel errado".
def papel_ativo(driver)
  driver.execute_script(
    "var s = document.querySelector(\"form[action*='change_role'] select[name='role_id']\");" \
    "return s ? s.options[s.selectedIndex].text.trim() : null;"
  )
rescue StandardError
  nil
end

# O combo so e renderizado para contas com dois ou mais papeis.
def switch_role!(driver, wait, role_name)
  driver.navigate.to("#{BASE}/")
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  select_el = begin
    driver.find_element(css: "form[action*='change_role'] select[name='role_id']")
  rescue Selenium::WebDriver::Error::NoSuchElementError
    abort "Combo de troca de papel ausente. A conta #{USER} precisa de pelo " \
          "menos dois papeis para que ele seja renderizado."
  end
  disponiveis = select_el.find_elements(tag_name: "option").map { |o| o.text.strip }
  unless disponiveis.include?(role_name)
    abort "Papel #{role_name.inspect} nao esta entre os da conta: #{disponiveis.inspect}"
  end

  Selenium::WebDriver::Support::Select.new(select_el).select_by(:text, role_name)
  # O select tem onchange: this.form.submit(), entao a troca ja foi submetida.
  wait.until { driver.execute_script("return document.readyState") == "complete" }

  # Conferir e o ponto: POST aceito nao garante papel trocado.
  driver.navigate.to("#{BASE}/")
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  ativo = papel_ativo(driver)
  abort "Troca de papel nao pegou: esperado #{role_name.inspect}, ativo #{ativo.inspect}" if ativo != role_name
  puts "papel ativo: #{ativo}"
end

def settle(driver, wait)
  wait.until { driver.execute_script("return document.readyState") == "complete" }
  wait.until { driver.execute_script("return (typeof jQuery === 'undefined') || jQuery.active === 0") }
rescue Selenium::WebDriver::Error::TimeoutError
  # segue mesmo assim; o screenshot dirá o estado
end

def shot(driver, name)
  height = driver.execute_script(
    "return Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)"
  ).to_i rescue 1600
  driver.manage.window.resize_to(1440, [[height + 120, 900].max, 6000].min)
  path = File.join(OUT, "#{name}.png")
  driver.save_screenshot(path)
  driver.manage.window.resize_to(1440, 1600)
  puts "  screenshot: #{name}.png"
  path
end

def console_severe(driver)
  driver.logs.get(:browser)
    .select { |m| m.level == "SEVERE" }
    .map { |m| m.message.to_s.lines.first.to_s.strip }
    .uniq
rescue StandardError
  []
end

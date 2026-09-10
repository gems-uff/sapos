# frozen_string_literal: true

# Constroi o driver do Selenium para os scripts desta pasta, escolhendo o
# navegador por SELENIUM_BROWSER -- a mesma variavel que a suite honra em
# spec/rails_helper.rb: `chrome` (default) ou `firefox`. O driver de cada um vem
# pelo Selenium Manager do selenium-webdriver, sem gem extra.
#
# Por que dois navegadores: parte do que o Rails emite e contorno de bug de
# navegador (o autocomplete="off" nos hidden e contorno de um bug do Firefox), e
# so o navegador que tinha o bug acusa a regressao. Capture os dois lados com o
# MESMO navegador; a comparacao e sempre navegador contra o mesmo navegador.
#
# O que muda entre eles, e que os scripts precisam saber:
#   - `driver.logs.get(:browser)` e `(:performance)` so existem no Chrome. No
#     Firefox `console_disponivel?` devolve false, e a captura deve registrar
#     que o sinal de console NAO foi medido -- zero erro ali e ausencia de
#     instrumento, nao ausencia de erro.
#   - `--hide-scrollbars` e `--force-device-scale-factor` sao do Chrome; o
#     Firefox headless ja renderiza sem barra e em escala 1.
require "selenium-webdriver"

NAVEGADOR = ENV.fetch("SELENIUM_BROWSER", "chrome").to_sym

def novo_driver(largura: 1440, altura: 1600, logs: true)
  case NAVEGADOR
  when :firefox
    options = Selenium::WebDriver::Firefox::Options.new
    options.add_argument("-headless")
    options.add_argument("--width=#{largura}")
    options.add_argument("--height=#{altura}")
    options.add_preference("intl.accept_languages", "pt-BR")
    Selenium::WebDriver.for(:firefox, options: options)
  when :chrome
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--window-size=#{largura},#{altura}")
    options.add_argument("--hide-scrollbars")
    options.add_argument("--force-device-scale-factor=1")
    options.add_argument("--lang=pt-BR")
    options.add_option("goog:loggingPrefs", { browser: "ALL", performance: "ALL" }) if logs
    Selenium::WebDriver.for(:chrome, options: options)
  else
    abort "SELENIUM_BROWSER=#{NAVEGADOR}: use chrome ou firefox"
  end
end

def console_disponivel?
  NAVEGADOR == :chrome
end

# frozen_string_literal: true

# O reset! do Capybara entre exemplos limpa o Chrome com
# Storage.clearDataForOrigin e origin "*", que o Chrome recusa desde a
# versão 158 ("invalid argument: * is not a valid URL"): todo feature spec
# quebrava no Chrome. Aqui o "*" vira o que o Chrome aceita: os cookies de
# todos os sites e o armazenamento local só do servidor que o Capybara sobe,
# o único que os feature specs visitam. O resto do execute_cdp, privado na
# gem, passa intacto.
#
# Sai quando o Capybara corrigir: teamcapybara/capybara#2865. Num upgrade do
# Capybara, confira se o reset! ainda chama execute_cdp com esse comando.
module CapybaraChromeReset
  private
    def execute_cdp(cmd, params = {})
      return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

      super("Network.clearBrowserCookies")
      server = Capybara.current_session.server
      return unless server && params[:storageTypes].to_s.include?("local_storage")

      super(cmd, { origin: server.base_url, storageTypes: "local_storage" })
    end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeReset)

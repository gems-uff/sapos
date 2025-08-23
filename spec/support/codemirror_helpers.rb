# frozen_string_literal: true

module CodemirrorHelper
  def select_all_keys
    if RUBY_PLATFORM.include?("darwin")
      chr = :meta  # Command+A no macOS
    else
      chr = :control  # Ctrl+A no Linux/Windows
    end
    page.driver.browser.action.key_down(chr).send_keys("a").key_up(chr).perform
  end
end

RSpec.configure do |config|
  config.include CodemirrorHelper, type: :feature
end

# frozen_string_literal: true

module CodemirrorHelper
  def select_all_keys
    if RUBY_PLATFORM.include?("darwin")
      [:meta, "a"]    # Command+A no macOS
    else
      [:control, "a"] # Ctrl+A no Linux/Windows
    end
  end
end

RSpec.configure do |config|
  config.include CodemirrorHelper, type: :feature
end

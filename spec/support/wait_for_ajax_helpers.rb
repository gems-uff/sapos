# frozen_string_literal: true

# Workaround for Chrome 116+ CDP bug: "Node with given id does not belong to
# the document". After a page navigation, Chrome may still have stale CDP node
# references internally. When Capybara checks element visibility those stale
# IDs cause an UnknownError. Patching synchronize to treat that specific error
# as retriable makes Capybara wait and retry instead of failing immediately.
if defined?(Capybara::Node::Base)
  module CapybaraChromeCDPFix
    CDP_STALE_NODE_MSG = "Node with given id does not belong to the document"

    def synchronize(seconds = nil, errors: nil, &block)
      super(seconds, errors: errors, &block)
    rescue Selenium::WebDriver::Error::UnknownError => e
      raise unless e.message.include?(CDP_STALE_NODE_MSG)
      sleep 0.1
      super(seconds, errors: errors, &block)
    end
  end

  Capybara::Node::Base.prepend(CapybaraChromeCDPFix)
end

module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      until finished_all_ajax_requests?
        sleep 0.01
      end
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script(
      'document.readyState === "complete" && ' \
      '(typeof jQuery === "undefined" || jQuery.active === 0)'
    )
  rescue Selenium::WebDriver::Error::UnknownError
    false
  end

  def click_button_and_wait(*args, **kwargs)
    click_button(*args, **kwargs)
    wait_for_ajax
  end

  def click_link_and_wait(*args, **kwargs)
    click_link(*args, **kwargs)
    wait_for_ajax
  end
end

RSpec.configure do |config|
  config.include WaitForAjax, type: :feature
end

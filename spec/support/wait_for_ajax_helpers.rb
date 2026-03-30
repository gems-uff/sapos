# frozen_string_literal: true

module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      until finished_all_ajax_requests?
        sleep 0.01
      end
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('typeof jQuery !== "undefined" && jQuery.active === 0')
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

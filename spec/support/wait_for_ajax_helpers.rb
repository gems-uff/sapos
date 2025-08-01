module Capybara
  module Node
    module Actions
      alias_method :original_click_button, :click_button

      def click_button(locator = nil, **options)
        original_click_button(locator, **options)
        wait_for_ajax_if_jquery_present
      end

      private

      def wait_for_ajax_if_jquery_present
        return unless evaluate_script('typeof jQuery !== "undefined"') rescue false

        Timeout.timeout(Capybara.default_max_wait_time) do
          loop until evaluate_script('jQuery.active').zero?
        end
      end
    end
  end
end
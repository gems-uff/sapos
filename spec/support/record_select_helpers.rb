
# frozen_string_literal: true

module RecordSelectHelpers
  def search_record_select(field, plural, value)
    record_select = open_record_select("#search_#{field}", plural)
    record_select.send_keys value
    sleep(0.5)
    find("#record-select-#{plural} .current").click
  end

  def fill_record_select(field, plural, value)
    record_select = open_record_select("#record_#{field}", plural)
    record_select.native.clear
    record_select.send_keys value
    sleep(0.5)
    find("#record-select-#{plural} .current").click
  end

  def expect_to_have_record_select(page, field, plural)
    input = click_record_select_input("#record_#{field}")
    ensure_record_select_open(input, plural)
    expect(page).to have_selector("#record-select-#{plural}", visible: true)
  end

  # Clicks the record-select input and waits until its dropdown is open with
  # records loaded. RecordSelect ignores keystrokes while the dropdown is
  # closed (onkeyup checks is_open), so typing before the open AJAX completes
  # would be silently lost.
  def open_record_select(selector, plural)
    input = click_record_select_input(selector)
    ensure_record_select_open(input, plural)
    find("#record-select-#{plural} li.record", match: :first)
    input
  end

  # A click only opens the dropdown through the focus event; if the field was
  # already focused (ActiveScaffold autofocuses the first form field) or the
  # RecordSelect observers were not attached yet, the click opens nothing.
  # Blur and click again in that case.
  def ensure_record_select_open(input, plural)
    return if page.has_selector?("#record-select-#{plural}", visible: true)
    page.execute_script("document.activeElement.blur()")
    sleep(0.2)
    input.click
  end

  # RecordSelect auto-opens its dropdown when ActiveScaffold focuses the first
  # form field, and if the form is still being positioned the dropdown may end
  # up overlapping the input. Selenium then rejects the click without it ever
  # reaching the page, so the dropdown never closes and every retry fails.
  # Pressing Escape closes the stray dropdown; the input must also be blurred,
  # otherwise the retried click fires no focus event and the dropdown (which
  # only opens on focus) would never reopen.
  def click_record_select_input(selector)
    input = find(selector)
    begin
      input.click
    rescue Selenium::WebDriver::Error::ElementClickInterceptedError
      page.send_keys :escape
      page.execute_script("document.activeElement.blur()")
      sleep(0.2)
      input.click
    end
    input
  end
end


# frozen_string_literal: true

module RecordSelectHelpers
  def search_record_select(field, plural, value)
    record_select = find("#search_#{field}").click
    wait_for_ajax
    record_select.send_keys value
    sleep(0.5)
    find("#record-select-#{plural} .current").click
  end

  def fill_record_select(field, plural, value)
    record_select = find("#record_#{field}").click
    record_select.native.clear
    record_select.send_keys value
    sleep(0.5)
    find("#record-select-#{plural} .current").click
  end

  def expect_to_have_record_select(page, field, plural)
    find("#record_#{field}").click
    sleep(0.3)
    expect(page).to have_selector("#record-select-#{plural}", visible: true)
  end
end

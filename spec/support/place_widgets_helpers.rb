
# frozen_string_literal: true

module PlaceWidgetsHelpers
  def prepare_city_widget(destroy_later)
    destroy_later << country1 = FactoryBot.create(:country, name: "Brasil")
    destroy_later << country2 = FactoryBot.create(:country, name: "USA")
    destroy_later << state11 = FactoryBot.create(:state, name: "RJ", country: country1)
    destroy_later << state12 = FactoryBot.create(:state, name: "SP", country: country1)
    destroy_later << FactoryBot.create(:state, name: "NY", country: country2)
    destroy_later << FactoryBot.create(:state, name: "AZ", country: country2)
    destroy_later << FactoryBot.create(:city, name: "Niteroi", state: state11)
    destroy_later << FactoryBot.create(:city, name: "Rio", state: state11)
    destroy_later << FactoryBot.create(:city, name: "Sao Paulo", state: state12)
    destroy_later << FactoryBot.create(:city, name: "Campinas", state: state12)
  end

  # Uses waiting matchers (have_select) instead of wait_for_ajax + page.all,
  # which asserted on whatever was in the DOM at that instant and failed if
  # the cascade AJAX had not repopulated the options yet. Selecting an option
  # that only exists after a cascade (e.g. "RJ" after picking "Brasil") also
  # waits, because find(:option, text:) retries until the option appears.
  def expect_to_have_city_widget(page, city_field, state_field, country_field)
    city_select = "widget_record_#{city_field}"
    state_select = "widget_record_#{state_field}"
    country_select = "widget_record_#{country_field}"

    expect(page).to have_select(city_select, options: ["Selecione a cidade"])
    expect(page).to have_select(state_select, options: ["Selecione o estado"])
    expect(page).to have_select(country_select, options: ["Selecione o país", "Brasil", "USA"])

    find(:select, country_select).find(:option, text: "Brasil").select_option
    expect(page).to have_select(state_select, options: ["Selecione o estado", "RJ", "SP"])
    find(:select, country_select).find(:option, text: "Selecione o país").select_option
    expect(page).to have_select(state_select, options: ["Selecione o estado"])
    find(:select, country_select).find(:option, text: "Brasil").select_option

    find(:select, state_select).find(:option, text: "RJ").select_option
    expect(page).to have_select(city_select, options: ["Selecione a cidade", "Niteroi", "Rio"])
    find(:select, state_select).find(:option, text: "Selecione o estado").select_option
    expect(page).to have_select(city_select, options: ["Selecione a cidade"])
    find(:select, state_select).find(:option, text: "RJ").select_option

    find(:select, city_select).find(:option, text: "Niteroi").select_option
    find(:select, state_select).find(:option, text: "Selecione o estado").select_option
    expect(page).to have_select(city_select, options: ["Selecione a cidade"])
    find(:select, state_select).find(:option, text: "RJ").select_option
    find(:select, city_select).find(:option, text: "Niteroi").select_option
    find(:select, country_select).find(:option, text: "Selecione o país").select_option
    expect(page).to have_select(state_select, options: ["Selecione o estado"])
    expect(page).to have_select(city_select, options: ["Selecione a cidade"])
  end

  def expect_to_have_identity_issuing_place_widget(page, field, record_id = "")
    expect(page).to have_selector("input#record_#{field}_#{record_id}", visible: true)
  end
end

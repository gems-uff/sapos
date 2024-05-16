
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

  def expect_to_have_city_widget(page, city_field, state_field, country_field)
    expect(page.all("select#widget_record_#{city_field} option").map(&:text)).to eq ["Selecione a cidade"]
    expect(page.all("select#widget_record_#{state_field} option").map(&:text)).to eq ["Selecione o estado"]
    expect(page.all("select#widget_record_#{country_field} option").map(&:text)).to eq ["Selecione o país", "Brasil", "USA"]

    find(:select, "widget_record_#{country_field}").find(:option, text: "Brasil").select_option
    expect(page.all("select#widget_record_#{state_field} option").map(&:text)).to eq ["Selecione o estado", "RJ", "SP"]
    find(:select, "widget_record_#{country_field}").find(:option, text: "Selecione o país").select_option
    expect(page.all("select#widget_record_#{state_field} option").map(&:text)).to eq ["Selecione o estado"]
    find(:select, "widget_record_#{country_field}").find(:option, text: "Brasil").select_option

    find(:select, "widget_record_#{state_field}").find(:option, text: "RJ").select_option
    expect(page.all("select#widget_record_#{city_field} option").map(&:text)).to eq ["Selecione a cidade", "Niteroi", "Rio"]
    find(:select, "widget_record_#{state_field}").find(:option, text: "Selecione o estado").select_option
    expect(page.all("select#widget_record_#{city_field} option").map(&:text)).to eq ["Selecione a cidade"]
    find(:select, "widget_record_#{state_field}").find(:option, text: "RJ").select_option

    find(:select, "widget_record_#{city_field}").find(:option, text: "Niteroi").select_option
    find(:select, "widget_record_#{state_field}").find(:option, text: "Selecione o estado").select_option
    expect(page.all("select#widget_record_#{city_field} option").map(&:text)).to eq ["Selecione a cidade"]
    find(:select, "widget_record_#{state_field}").find(:option, text: "RJ").select_option
    find(:select, "widget_record_#{city_field}").find(:option, text: "Niteroi").select_option
    find(:select, "widget_record_#{country_field}").find(:option, text: "Selecione o país").select_option
    expect(page.all("select#widget_record_#{state_field} option").map(&:text)).to eq ["Selecione o estado"]
    expect(page.all("select#widget_record_#{city_field} option").map(&:text)).to eq ["Selecione a cidade"]
  end

  def expect_to_have_identity_issuing_place_widget(page, field, record_id = "")
    expect(page).to have_selector("input#record_#{field}_#{record_id}", visible: true)
  end
end

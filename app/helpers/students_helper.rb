# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module StudentsHelper
  def enrollments_column(record, column)
    return record.enrollments_number
  end

  def city_form_column(record, options)
    city = record.city || City.new
    state = city.state || State.new
    country = state.country || Country.new

    city_widget(
      country: :address_country, state: :address_state, city: :city,
      selected_country: country.id,
      selected_state: state.id,
      selected_city: city.id
    )
  end

  def birth_city_form_column(record, options)
    city = record.birth_city || City.new
    state = city.state || record.birth_state || State.new
    country = state.country || Country.new

    city_widget(
      country: :birth_country, state: :birth_state, city: :birth_city,
      selected_country: country.id,
      selected_state: state.id,
      selected_city: city.id
    )
  end

  def identity_issuing_place_form_column(record, options)
    identity_issuing_place_widget(
      text: record.identity_issuing_place
    )
  end
  
  def photo_show_column(record, column)
    image_tag photo_student_path(record)
  end

end
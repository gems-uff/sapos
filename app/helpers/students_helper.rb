# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module StudentsHelper
  include StudentHelperConcern

  # StudentHelperConcern
  alias_method(
    :city_form_column,
    :custom_city_form_column
  )
  alias_method(
    :birth_city_form_column,
    :custom_birth_city_form_column
  )
  alias_method(
    :identity_issuing_place_form_column,
    :custom_identity_issuing_place_form_column
  )
  alias_method(
    :photo_form_column,
    :custom_photo_form_column
  )

  def enrollments_column(record, column)
    record.enrollments_number
  end

  def photo_show_column(record, column)
    return "-" if record.photo.blank?
    image_tag(
      photo_student_path(record) + "?hash=#{record.photo_before_type_cast}",
      style: "width: 400px; height: 300px; Object-fit: contain;
              background-color: #f2f1f0;"
    )
  end

  def permit_rs_browse_params
    [:page, :update, :utf8]
  end
end

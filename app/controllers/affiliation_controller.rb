# frozen_string_literal: true

class AffiliationController < ApplicationController
  authorize_resource

  active_scaffold :affiliation do |config|
    columns = [:professor, :institution, :start_date, :end_date, :active]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:professor].form_ui = :record_select
    config.columns[:institution].form_ui = :record_select
    config.columns[:start_date].form_ui = :date_picker
    config.columns[:active].form_ui = :checkbox
    config.columns[:end_date].form_ui = :date_picker
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )

  def populate
    professor_versions = PaperTrail::Version.where(item_type: "Professor")
    professor_versions.each do |version|
      professor = version.reify
      if version.event.eql?("create")
        Affiliation.create(
          professor_id: professor.id,
          institution_id: professor.institution_id,
          start_date: version.created_at,
          active: true
        )
      elsif version.event.eql?("update") &&
        Affiliation.where(professor_id: professor.id, institution_id: professor.institution_id).blank?
        aff = Affiliation.where(professor_id: professor.id).last
        aff.update(end_date: version.created_at, active: false)
        Affiliation.create(
          professor_id: professor.id,
          institution_id: professor.institution_id,
          start_date: version.created_at,
          active: true
        )
      elsif version.event.eql?("destroy")
        aff = Affiliation.where(professor_id: professor.id, institution_id: professor.institution_id).last
        aff.update(end_date: version.created_at, active: false)
      end
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CarrierwaveFilesController < ApplicationController
  include PanelHelper

  authorize_resource class: false, instance_name: :panel

  active_scaffold :"carrier_wave/storage/active_record/active_record_file" do |config|
    config.label = I18n.t("panel.garbage_collector.title")
    config.actions = [:list, :show, :delete, :field_search]

    config.list.columns = [:id, :original_filename, :content_type, :size, :created_at]
    config.show.columns = [:id, :original_filename, :content_type, :size, :created_at, :preview]
    config.list.sorting = { created_at: :desc }

    config.columns.add :preview
    config.columns[:preview].sort = false

    config.field_search.columns = [:original_filename, :content_type]
    config.columns[:original_filename].search_ui = :text
    config.columns[:content_type].search_ui = :text

    config.columns[:id].label = I18n.t("panel.garbage_collector.id")
    config.columns[:original_filename].label = I18n.t("panel.garbage_collector.filename")
    config.columns[:content_type].label = I18n.t("panel.garbage_collector.content_type")
    config.columns[:size].label = I18n.t("panel.garbage_collector.size")
    config.columns[:created_at].label = I18n.t("panel.garbage_collector.created_at")
    config.columns[:preview].label = I18n.t("panel.garbage_collector.preview")

    config.delete.link.confirm = I18n.t("panel.garbage_collector.confirm_delete")

    config.action_links.add :delete_all,
      label: I18n.t("panel.garbage_collector.delete_all"),
      method: :post,
      page: true,
      confirm: I18n.t("panel.garbage_collector.confirm_delete_all"),
      type: :collection,
      crud_type: :delete,
      position: :top
  end

  def delete_all
    raise CanCan::AccessDenied.new if cannot?(:destroy, CarrierWave::Storage::ActiveRecord::ActiveRecordFile)

    each_record_in_page { }
    filtered_records = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items

    return redirect_to(panel_carrierwave_files_path) if filtered_records.empty?

    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    filtered_ids = filtered_records.map(&:id)
    count = cw.where(id: filtered_ids).destroy_all.count

    flash[:notice] = I18n.t("panel.garbage_collector.deleted", count: count)
    redirect_to panel_carrierwave_files_path
  end

  protected

  def conditions_for_collection
    orphan_ids = find_carrierwave_orphan_ids
    if orphan_ids.present?
      ["carrier_wave_files.id IN (?)", orphan_ids]
    else
      ["1 = 0"]
    end
  end
end

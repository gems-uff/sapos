# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CarrierwaveFilesController < ApplicationController
  include PanelEnabledConcern

  helper Panel::CarrierwaveFilesHelper

  authorize_resource class: false, instance_name: :panel

  active_scaffold :"carrier_wave/storage/active_record/active_record_file" do |config|
    config.label = I18n.t("panel.garbage_collector.title")
    config.actions = [:list, :show, :delete, :field_search]

    config.list.columns = [:id, :original_filename, :content_type, :size, :created_at, :original_model]
    config.show.columns = [:id, :original_filename, :content_type, :size, :created_at, :preview]
    config.list.sorting = { created_at: :desc }

    config.columns.add :preview
    config.columns[:preview].sort = false

    config.columns.add :original_model
    config.columns[:original_model].sort = false
    config.columns[:original_model].label = I18n.t("panel.garbage_collector.original_model")

    config.field_search.columns = [:original_filename, :content_type, :original_model]
    config.columns[:original_filename].search_ui = :text
    config.columns[:content_type].search_ui = :text
    config.columns[:original_model].search_sql = ""
    config.columns[:original_model].search_ui = :text

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
      position: :top,
      dynamic_parameters: -> { search_params.present? ? { search: search_params } : {} }

    config.action_links.add :run_mark_and_sweep,
      label: I18n.t("panel.garbage_collector.run_mark_and_sweep"),
      method: :post,
      page: true,
      confirm: nil,
      type: :collection,
      crud_type: :create,
      position: :top
  end

  def run_mark_and_sweep
    raise CanCan::AccessDenied.new if cannot?(:read, CarrierWave::Storage::ActiveRecord::ActiveRecordFile)
    count = Panel::CarrierwaveFilesHelper.run_mark_and_sweep!
    flash[:notice] = I18n.t("panel.garbage_collector.scan_done", count: count)
    redirect_to carrierwave_files_path
  end

  def delete_all
    raise CanCan::AccessDenied.new if cannot?(:destroy, CarrierWave::Storage::ActiveRecord::ActiveRecordFile)

    # Um filtro que chega no POST (via dynamic_parameters do action link) e
    # persistido na sessao, de onde o do_search abaixo o le. O guard evita o outro
    # ramo de store_search_params_into_session, que APAGA o filtro salvo quando
    # params[:search] esta vazio.
    store_search_params_into_session if params[:search].present?

    each_record_in_page { }
    filtered_records = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items

    return redirect_to(carrierwave_files_path) if filtered_records.empty?

    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    filtered_ids = filtered_records.map(&:id)
    count = cw.where(id: filtered_ids).destroy_all.count
    CarrierwaveOrphanFile.where(carrierwave_file_id: filtered_ids).delete_all

    flash[:notice] = I18n.t("panel.garbage_collector.deleted", count: count)
    redirect_to carrierwave_files_path
  end

  protected

  # Also removes the orphan tracking row so it does not dangle until the next
  # mark-and-sweep scan.
  def do_destroy(record = nil)
    record ||= destroy_find_record
    super(record)
    if successful? && record
      CarrierwaveOrphanFile.where(carrierwave_file_id: record.id).delete_all
    end
  end

  def conditions_for_collection
    ["carrier_wave_files.id IN (SELECT carrierwave_file_id FROM carrierwave_orphan_files)"]
  end

  def self.condition_for_original_model_column(column, value, like_pattern)
    return nil if value.blank?
    term = "%#{value.downcase}%"
    matching_ids = CarrierwaveOrphanFile
      .where("LOWER(original_model) LIKE ?", term)
      .pluck(:carrierwave_file_id)
    if matching_ids.present?
      ["carrier_wave_files.id IN (?)", matching_ids]
    else
      ["1 = 0"]
    end
  end
end

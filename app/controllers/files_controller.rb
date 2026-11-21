# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class FilesController < ApplicationController
  skip_authorization_check
  skip_authorize_resource
  skip_before_action :authenticate_user!
  skip_before_action :prepare_background
  before_action :set_show_background

  def download
    medium_hash = params[:hash]  # Compability with old admissions url
    if medium_hash.nil?
      medium_hash = params[:medium_hash]
      medium_hash = "#{medium_hash}.#{params[:format]}" if params[:format].present?
    end
    record = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.where(
      medium_hash: medium_hash
    ).first
    if record.blank?
      raise ActionController::RoutingError.new("Não encontrado")
    end
    type = Mime::Type.lookup_by_extension(
      File.extname(record.original_filename.to_s).delete_prefix(".").downcase
    ).to_s
    if INLINE_TYPES.include?(type)
      send_data(record.read, filename: record.original_filename, type: type, disposition: :inline)
    else
      send_data(
        record.read, filename: record.original_filename,
        type: "application/octet-stream", disposition: :attachment
      )
    end
  end

  # O arquivo vem de quem preenche o formulario de candidatura, e a rota nao
  # pede login. Abre no navegador so o que nao executa codigo; o resto, inclusive
  # HTML e SVG, vai como download de tipo generico, para o navegador nunca o
  # tratar como pagina do SAPOS.
  INLINE_TYPES = %w[application/pdf image/png image/jpeg image/gif].freeze

  private
    def set_show_background
      @show_background = true
    end
end

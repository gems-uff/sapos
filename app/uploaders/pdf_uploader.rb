# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PdfUploader < CarrierWave::Uploader::Base
  storage :active_record
  cache_storage :file

  configure do |config|
    config.root = Rails.root
  end

  class FilelessIO < StringIO
    attr_accessor :original_filename
    attr_accessor :content_type
  end

  # Param must be a hash with to 'base64_contents' and 'filename'.
  def cache!(file)
    return if file.blank?
    if defined? file.file
      file = file.file
    end
    # avoid the carrier_wave to create duplicate database entry of same file due file termination case
    if (defined? file.original_filename) && (file.original_filename.is_a? String)
      file.original_filename.downcase!
    end
    if file.respond_to?(:has_key?) && file.has_key?(:base64_contents) && file.has_key?(:filename)
      local_file = FilelessIO.new(Base64.decode64(file[:base64_contents]))
      local_file.original_filename = file[:filename]
      extension = File.extname(file[:filename])[1..-1]
      local_file.content_type = Mime::Type.lookup_by_extension(extension).to_s
      super(local_file)
    else
      super(file)
    end
  end
end

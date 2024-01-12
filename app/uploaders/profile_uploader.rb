# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ProfileUploader < FormFileUploader
  def url
    "#{ENV['RAILS_RELATIVE_URL_ROOT']}/files/#{model.photo_before_type_cast}"
  end

  def extension_allowlist
    %w(jpg jpeg gif png)
  end

  def content_type_allowlist
    /image\//
  end
end

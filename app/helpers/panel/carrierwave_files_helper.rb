# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Panel::CarrierwaveFilesHelper
  def size_column(record, column)
    number_to_human_size(record.size) if record.size.present?
  end

  def preview_show_column(record, column)
    return "-" if record.medium_hash.blank?

    if record.content_type.to_s.start_with?("image/")
      link_to(
        image_tag(download_path(record.medium_hash),
                  style: "max-width: 400px; max-height: 300px; object-fit: contain;"),
        download_path(record.medium_hash),
        target: "_blank"
      )
    else
      link_to I18n.t("panel.garbage_collector.download"),
              download_path(record.medium_hash),
              target: "_blank"
    end
  end
end

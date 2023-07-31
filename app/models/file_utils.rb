# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module FileUtils
  def self.file_content(name, type = "rb")
    file_to_open = [Rails.root, name].join(File::Separator)
    file = File.open(file_to_open, type)
    file.read
  end
end

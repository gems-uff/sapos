# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module FormImagesHelper

  def form_column(record, options)
    text_area(record, :text, options.merge(:columns => 10))
  end

end
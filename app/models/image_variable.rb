# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ImageVariable
  def initialize(value)
    value ||= ''
    splitted = value.split('|')
    @url = "custom_variables/#{splitted[0]}"
    @filename = splitted[0]
    @scale = splitted[1].to_f
    @x = splitted[2].to_i
    @y = splitted[3].to_i
  end

  def url
    @url
  end

  def filename
    @filename
  end

  def scale
    @scale
  end

  def x
    @x
  end

  def y
    @y
  end
  

end
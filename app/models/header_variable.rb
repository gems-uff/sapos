# coding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class HeaderVariable

  SEPARATOR = '|'
  HEIGHT = 90

  def initialize(options={})
    value = options[:value] || ''
    if not value.empty?
      splitted = value.split(SEPARATOR)
      @filename = splitted[0]
      @scale = splitted[1].to_f
      @x = splitted[2].to_i
      @y = splitted[3].to_i
      @text = splitted[4]
    else
      @filename = (options[:filename] || "logoUFF.jpg")
      @scale = (options[:scale] || "0.4").to_f
      @x = (options[:x] || "13").to_i
      @y = (options[:y] || "13").to_i
      @text = (options[:text] || "UNIVERSIDADE FEDERAL FLUMINENSE
INSTITUTO DE COMPUTAÇÃO
PROGRAMA DE PÓS-GRADUAÇÃO EM COMPUTAÇÃO")
    end
    @url = "custom_variables/#{@filename}"
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

  def image_x
    @x
  end

  def image_y
    HEIGHT - @y
  end
  
  
  def text
    @text
  end

  def to_s
    "#{@filename}#{SEPARATOR}#{@scale}#{SEPARATOR}#{@x}#{SEPARATOR}#{@y}#{SEPARATOR}#{@text}"
  end

end
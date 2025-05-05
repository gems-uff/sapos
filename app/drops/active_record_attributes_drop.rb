# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ActiveRecordAttributesDrop < Liquid::Drop
  @@global_inspect_attributes = {}
  @@defined_attributes = {}

  def initialize(record)
    @record = record
    self.class.define_attribute_methods(record)
  end

  def self.define_attribute_methods(record)
    klass = record.class
    return if @@defined_attributes[klass]
    @@defined_attributes[klass] = []
    record.attributes.keys.each do |attr_name|
      @@defined_attributes[klass].push(attr_name)
      define_method(attr_name) do
        @record.public_send(attr_name)
      end
    end
  end

  def self.define_drop_relationship(attr_name, drop_class)
    if !@@global_inspect_attributes.key?(self)
      @@global_inspect_attributes[self] = {}
    end
    @@global_inspect_attributes[self][attr_name] = drop_class
    define_method(attr_name) do
      drop_class.new(@record.public_send(attr_name))
    end
  end

  def self.define_drop_relationship_many(attr_name, drop_class)
    if !@@global_inspect_attributes.key?(self)
      @@global_inspect_attributes[self] = {}
    end
    @@global_inspect_attributes[self][attr_name] = [drop_class]
    define_method(attr_name) do
      @record.public_send(attr_name).map { |v| drop_class.new(v) }
    end
  end

  def self.define_drop_accessor(attr_name)
    if !@@global_inspect_attributes.key?(self)
      @@global_inspect_attributes[self] = {}
    end
    @@global_inspect_attributes[self][attr_name] = :value
    define_method(attr_name) do
      @record.public_send(attr_name)
    end
  end

  def to_s
    attributes = @@defined_attributes[@record.class].map do |attr_name|
      value = self.send(attr_name)
      value = value.methods.include?(:strftime) ? value.to_fs : value.to_s
      "#{attr_name}: '#{value}'"
    end
    @@global_inspect_attributes[self.class].each do |attr_name, value|
      if value == :value
        res = self.send(attr_name)
        attributes.push("#{attr_name}: #{res}")
      elsif value.kind_of?(Array)
        attributes.push("#{attr_name}: [#{value.name}*]")
      else
        attributes.push("#{attr_name}: #{value.name}?")
      end
    end
    "#{@record.class.name}(#{attributes.join(', ')})"
  end
end

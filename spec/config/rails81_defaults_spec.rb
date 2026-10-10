# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O config/application.rb sobe para `load_defaults 8.1` com uma justificativa por
# flag, e cada justificativa apoia-se numa PREMISSA sobre este projeto. Estes
# exemplos fixam as premissas -- o que, se mudar, obriga a reler o comentario --,
# e nao o comportamento do Rails, que a suite do Rails ja cobre.
RSpec.describe "premissas do load_defaults 8.1" do
  # raise_on_missing_required_finder_order_columns so levanta em modelo sem
  # primary_key, implicit_order_column e query_constraints. A premissa e que nao
  # ha modelo assim aqui.
  it "toda tabela de modelo tem chave primaria" do
    Rails.application.eager_load!
    sem_chave = ActiveRecord::Base.descendants
      .reject(&:abstract_class?)
      .filter_map { |m| m.name if m.table_exists? && m.primary_key.nil? }

    expect(sem_chave).to be_empty
  end

  # escape_json_responses = false sobrepoe o escape so no `render json:`; o
  # to_json interpolado em HTML nas views continua regido pelo
  # escape_html_entities_in_json, que permanece ligado.
  it "o to_json das views continua escapando HTML; so o render json: deixou de" do
    expect(ActiveSupport.escape_html_entities_in_json).to be true
    expect(ActionController::Base.escape_json_responses).to be false
    expect({ n: "<" }.to_json).to eq('{"n":"\u003c"}')
  end

  # variant_processor = :disabled existe porque o default :vips carrega
  # image_processing/vips no boot, que exige ruby-vips -- ausente do bundle.
  # Se um dia a gem entrar, esta premissa cai e a linha merece ser revista.
  it "nao ha ruby-vips no bundle, e o Active Storage usa o NullTransformer" do
    expect(Gem.loaded_specs).not_to have_key("ruby-vips")
    expect(ActiveStorage.variant_processor).to eq(:disabled)
    expect(ActiveStorage.variant_transformer).to eq(ActiveStorage::Transformers::NullTransformer)
  end

  # remove_hidden_field_autocomplete = true: o atributo era contorno de bug do
  # Firefox, e a homologacao mediu que o bug nao se manifesta. Se o atributo
  # voltar, foi decisao -- e o comentario do application.rb precisa acompanhar.
  it "hidden gerado por helper sai sem autocomplete" do
    expect(ApplicationController.helpers.hidden_field_tag(:x, 1)).not_to include("autocomplete")
  end
end

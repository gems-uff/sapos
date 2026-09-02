# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"
require "open3"

# Guarda do boot em RAILS_ENV=test que NAO passa pelo binario do rspec -- rake,
# console, runner, assets:precompile.
#
# O active_scaffold 4.3 registra o initializer 'active_scaffold.testing', que
# chama RSpec.configure quando defined?(RSpec). A guarda e frouxa: o
# Bundler.require do grupo :test define o modulo RSpec, mas RSpec.configure vem
# do rspec-core, que so e carregado pelo binario do rspec. Sem ele o
# initialize! estoura com NoMethodError e derruba db:schema:load, db:migrate e
# afins. Por isso o config/application.rb carrega o rspec-core quando o
# ambiente e o de teste.
#
# Este exemplo nao consegue medir isso dentro do proprio processo do rspec --
# ali o rspec-core sempre esta carregado, e a linha do application.rb parece
# inocua. Dai o subprocesso: e o unico jeito de a suite enxergar a regressao.
# Rodando so no CI, ela apareceria depois do commit, e como falha de db:schema:load,
# longe da linha que a causou.
RSpec.describe "Boot em RAILS_ENV=test fora do rspec" do
  it "carrega o ambiente sem estourar no initializer de teste do active_scaffold" do
    output, status = Open3.capture2e(
      { "RAILS_ENV" => "test", "BUNDLE_GEMFILE" => Rails.root.join("Gemfile").to_s },
      "bundle", "exec", "rails", "runner", "nil",
      chdir: Rails.root.to_s
    )

    expect(status).to be_success, "o boot falhou:\n#{output}"
    expect(output).not_to include("NoMethodError")
  end
end

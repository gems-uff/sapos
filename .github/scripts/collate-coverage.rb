# frozen_string_literal: true

# Junta a cobertura das máquinas que dividem a suíte no CI e escreve o
# coverage/coverage.xml (Cobertura) que os uploads publicam.
#
# uso: bundle exec ruby .github/scripts/collate-coverage.rb RESULTSET...
#
# Cada máquina roda parte dos arquivos sob o parallel_rspec, e o
# coverage/.resultset.json dela guarda uma entrada por worker; o coverage.xml
# que ela escreve cobre só a parte dela. O collate soma as entradas de todas.
# O perfil é o "rails" do spec/rails_helper.rb: o resultset guarda a cobertura
# crua, e os filtros entram aqui, na formatação.
require "simplecov"
require "simplecov-cobertura"

abort "uso: collate-coverage.rb RESULTSET..." if ARGV.empty?

SimpleCov.collate(ARGV, "rails") do
  formatter SimpleCov::Formatter::CoberturaFormatter
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# As opcoes de ano vivem na configuracao do active_scaffold, que o controller
# avalia uma vez, ao carregar a classe. Com a lista calculada ali, o ano
# corrente ficava o da carga: na suite, o controller carregado durante um
# travel_to de outro exemplo mostrava os anos daquela data; em producao, ate o
# processo reiniciar. YearSemester.selectable_years_options recalcula a cada
# vez que a lista e percorrida.
RSpec.describe "Opcoes de ano na configuracao dos controllers" do
  include ActiveSupport::Testing::TimeHelpers

  [
    ClassSchedulesController, CourseClassesController, EnrollmentHoldsController,
    EnrollmentRequestsController, ClassEnrollmentRequestsController,
    ClassEnrollmentsController
  ].each do |controller|
    it "#{controller.name} acompanha a data em que a lista e percorrida" do
      opcoes = controller.active_scaffold_config.columns[:year].options[:options]

      travel_to(Date.new(2021, 6, 1)) do
        expect(opcoes.to_a).to eq YearSemester.selectable_years
        expect(opcoes.to_a).to include(2021)
      end
      expect(opcoes.to_a).to eq YearSemester.selectable_years
      expect(opcoes.to_a).to include(Date.current.year)
    end
  end
end

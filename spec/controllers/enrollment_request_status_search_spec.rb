# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A busca de solicitacoes de inscricao por status so tinha o ramo Invalida
# exercitado. Sem cobertura (#720): Valida, Efetivada e Solicitada, que
# classificam a solicitacao pelo conjunto dos status das suas disciplinas.
RSpec.describe EnrollmentRequestsController do
  before(:each) do
    @turmas = FactoryBot.create_list(:course_class, 2)
    @valida = pedido(ClassEnrollmentRequest::VALID, ClassEnrollmentRequest::VALID)
    @efetivada = pedido(ClassEnrollmentRequest::EFFECTED, ClassEnrollmentRequest::EFFECTED)
    @mista = pedido(ClassEnrollmentRequest::VALID, ClassEnrollmentRequest::EFFECTED)
    @solicitada = pedido(ClassEnrollmentRequest::REQUESTED, ClassEnrollmentRequest::VALID)
    @invalida = pedido(ClassEnrollmentRequest::INVALID, ClassEnrollmentRequest::REQUESTED)
  end

  def pedido(*status)
    er = FactoryBot.create(:enrollment_request, year: 2020, semester: 1)
    status.each_with_index do |s, i|
      FactoryBot.create(:class_enrollment_request, enrollment_request: er, course_class: @turmas[i], status: s)
    end
    er
  end

  def busca(valor)
    EnrollmentRequest.where(*described_class.condition_for_status_column(nil, valor, nil))
  end

  it "Valida: nenhuma disciplina fora de valida/efetivada e ao menos uma valida" do
    expect(busca(ClassEnrollmentRequest::VALID)).to contain_exactly(@valida, @mista)
  end

  it "Efetivada: todas as disciplinas efetivadas" do
    expect(busca(ClassEnrollmentRequest::EFFECTED)).to contain_exactly(@efetivada)
  end

  it "Solicitada: nenhuma invalida e ao menos uma ainda nao validada" do
    expect(busca(ClassEnrollmentRequest::REQUESTED)).to contain_exactly(@solicitada)
  end

  it "valor fora da lista nao filtra" do
    expect(described_class.condition_for_status_column(nil, "", nil)).to be_nil
  end
end

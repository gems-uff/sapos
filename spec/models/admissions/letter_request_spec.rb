# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::LetterRequest, type: :model do
  it { should be_able_to_be_destroyed }

  it { should belong_to(:admission_application).required(true) }
  it { should belong_to(:filled_form).required(true) }

  before(:all) do
    @admission_application = FactoryBot.create(:admission_application, :in_process_with_letters)
    @filled_form = FactoryBot.create(:filled_form)
    @destroy_later = []
  end
  after(:all) do
    # before(:all) roda fora da transacao por exemplo do DatabaseCleaner, entao
    # o que ele cria fica visivel para os testes seguintes ate ser apagado aqui.
    # A trait :in_process_with_letters cria tambem um AdmissionProcess, com
    # simple_url fixo -- e ele nao era apagado. Qualquer teste posterior que
    # criasse um processo com a mesma URL no mesmo intervalo falhava, dependendo
    # da ordem sorteada.
    admission_process = @admission_application.admission_process
    @admission_application.delete
    @filled_form.delete
    admission_process&.destroy
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:letter_request) do
    Admissions::LetterRequest.new(
      name: "Ana",
      email: "ana@email.com",
      admission_application: @admission_application,
      filled_form: @filled_form
    )
  end
  subject { letter_request }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end
  # ToDo: test before_save
  # ToDo: test after_initialize

  describe "Methods" do
    # ToDo: status
    # ToDo: is_filled
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProgramLevel, type: :model do
  it { should be_able_to_be_destroyed }

  let(:program_level) { ProgramLevel.new(level: 1, start_date: Date.today) }
  subject { program_level }

  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:start_date) }

    # O programa tem um conceito por vez: dois períodos que se cruzam fariam o
    # on_date casar duas linhas para a mesma data. O término é exclusivo.
    describe "periods that overlap" do
      before(:each) do
        @anterior = FactoryBot.create(
          :program_level, level: 4, start_date: Date.new(2015, 1, 1), end_date: Date.new(2020, 1, 1)
        )
      end

      it "rejects a period that starts inside an existing one" do
        other = FactoryBot.build(:program_level, level: 5, start_date: Date.new(2018, 1, 1), end_date: nil)
        expect(other).to have_error(:overlapping_period).on(:base)
      end

      it "rejects a second open period" do
        FactoryBot.create(:program_level, level: 5, start_date: Date.new(2020, 1, 1), end_date: nil)
        other = FactoryBot.build(:program_level, level: 6, start_date: Date.new(2024, 1, 1), end_date: nil)
        expect(other).to have_error(:overlapping_period).on(:base)
      end

      # Controle das duas acima: o término é exclusivo, então começar no dia em
      # que o anterior termina não cruza.
      it "accepts a period that starts on the day the previous one ends" do
        other = FactoryBot.build(:program_level, level: 5, start_date: Date.new(2020, 1, 1), end_date: nil)
        expect(other).to be_valid
      end

      # Só o período alterado é julgado: um registro que já se cruzava e que
      # ninguém tocou nas datas continua editável.
      it "still saves an untouched overlapping record when only the ordinance changes" do
        legado = FactoryBot.build(:program_level, level: 5, start_date: Date.new(2018, 1, 1), end_date: nil)
        legado.save!(validate: false)
        legado.ordinance = "Portaria 1/2018"
        expect(legado).to be_valid
      end
    end

    describe "an unparseable end date" do
      ["31/02/2026", "2020", "banana"].each do |entrada|
        it "is rejected instead of saved as an open period: #{entrada.inspect}" do
          program_level.end_date = entrada
          expect(program_level.end_date).to be_nil, "o cast já descartou a entrada"
          expect(program_level).to have_error(:invalid_date).on(:end_date)
        end
      end
    end
  end

  describe "Scopes" do
    # Os três se cruzam de propósito, para exercitar as bordas do on_date com
    # poucas linhas; a validação de sobreposição os recusaria, daí o
    # save(validate: false).
    before(:each) do
      @active = gravar_sem_validar(start_date: Date.new(2020, 1, 1), end_date: nil)
      @inactive = gravar_sem_validar(start_date: Date.new(2020, 1, 1), end_date: Date.new(2022, 1, 1))
      @future = gravar_sem_validar(start_date: Date.new(2030, 1, 1), end_date: nil)
    end

    def gravar_sem_validar(**datas)
      FactoryBot.build(:program_level, **datas).tap { |record| record.save!(validate: false) }
    end

    describe "active" do
      it "returns only records with nil end_date" do
        result = ProgramLevel.active
        expect(result).to include(@active, @future)
        expect(result).not_to include(@inactive)
      end
    end

    describe "on_date" do
      it "returns records whose range covers the given date" do
        result = ProgramLevel.on_date(Date.new(2024, 6, 15))
        expect(result).to include(@active)
        expect(result).not_to include(@inactive, @future)
      end

      it "includes records with open end_date on future dates" do
        result = ProgramLevel.on_date(Date.new(2024, 6, 15))
        expect(result).to include(@active)
      end

      it "includes an expired record when the query date precedes end_date" do
        result = ProgramLevel.on_date(Date.new(2021, 6, 15))
        expect(result).to include(@inactive, @active)
        expect(result).not_to include(@future)
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "includes the level value" do
        program_level.level = 3
        expect(program_level.to_label).to include("3")
      end
    end

    describe "to_ordinance" do
      it "wraps ordinance in parentheses when present" do
        program_level.ordinance = "Portaria 109/2025"
        expect(program_level.to_ordinance).to eq("(Portaria 109/2025)")
      end

      it "returns empty string when ordinance is nil" do
        program_level.ordinance = nil
        expect(program_level.to_ordinance).to eq("")
      end
    end
  end
end

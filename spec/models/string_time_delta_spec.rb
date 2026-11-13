# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe StringTimeDelta do
  describe "multiply" do
    it ("should return 1 day if it is multiplying 1.day * 1") do
      expect(StringTimeDelta.multiply(1.day, 1)).to eq(1.day)
    end

    it ("should return 3 days if it is multiplying 1.day * 3") do
      expect(StringTimeDelta.multiply(1.day, 3)).to eq(3.days)
    end

    it ("should return -1 day if it is multiplying 1.day * -1") do
      expect(StringTimeDelta.multiply(1.day, -1)).to eq(-1.day)
    end

    it ("should return -3 days if it is multiplying 1.day * -3") do
      expect(StringTimeDelta.multiply(1.day, -3)).to eq(-3.days)
    end

    it ("should return 0 seconds if it is multiplying 1.day * 0") do
      expect(StringTimeDelta.multiply(1.day, 0)).to eq(0.seconds)
    end
  end

  describe "multiply" do
    it ("should return 1 second if it is parsing 1s") do
      expect(StringTimeDelta.parse("1s")).to eq(1.second)
    end

    it ("should return 1 minute if it is parsing 1m") do
      expect(StringTimeDelta.parse("1m")).to eq(1.minute)
    end

    it ("should return 2 hours if it is parsing 2h") do
      expect(StringTimeDelta.parse("2h")).to eq(2.hours)
    end

    it ("should return 3 days if it is parsing 3d") do
      expect(StringTimeDelta.parse("3d")).to eq(3.days)
    end

    it ("should return -1 week if it is parsing -1w") do
      expect(StringTimeDelta.parse("-1w")).to eq(-1.week)
    end

    it ("should return -3 months if it is parsing -3M") do
      expect(StringTimeDelta.parse("-3M")).to eq(-3.months)
    end

    it ("should return 1 year and 6 months if it is parsing 1y6M") do
      expect(StringTimeDelta.parse("1y6M")).to eq((1.year + 6.months))
    end

    it ("should return 15 days if it is parsing 15") do
      expect(StringTimeDelta.parse("15")).to eq(15.days)
    end
  end

  # Caracterizacao (#720): o algoritmo e copia do Rufus::Scheduler.parse_duration,
  # mas nao chama a gem. Estes exemplos prendem os cantos que o deslocamento das
  # notificacoes aceita hoje, inclusive os que truncam.
  describe "parse, nos cantos" do
    it "devolve zero para a string vazia" do
      expect(StringTimeDelta.parse("")).to eq(0.seconds)
    end

    it "soma unidades encadeadas" do
      expect(StringTimeDelta.parse("2d12h")).to eq(2.days + 12.hours)
    end

    it "le o numero solto depois de uma unidade como dias" do
      expect(StringTimeDelta.parse("1d2")).to eq(3.days)
    end

    it "trunca a fracao de uma unidade" do
      expect(StringTimeDelta.parse("1.5d")).to eq(1.day)
    end

    it "trunca a fracao de um numero solto" do
      expect(StringTimeDelta.parse("1.5")).to eq(1.day)
    end

    it "recusa texto fora do formato" do
      expect { StringTimeDelta.parse("1 dia") }.to raise_error(ArgumentError, "cannot parse '1 dia'")
    end

    it "recusa unidade sem numero" do
      expect { StringTimeDelta.parse("d") }.to raise_error(ArgumentError, "cannot parse 'd' (especially 'd')")
    end

    it "devolve nil em vez de recusar quando pedido" do
      expect(StringTimeDelta.parse("1 dia", no_error: true)).to be_nil
      expect(StringTimeDelta.parse("d", no_error: true)).to be_nil
    end
  end
end

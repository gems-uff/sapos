# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O identificador impresso no PDF assinado -- o que aparece na URL do QR Code e
# que uma pessoa pode ter de transcrever à mão -- não tinha teste nenhum. O
# golden-master de PDF fixa o gerador para tirar o acaso do baseline, e um mock
# sem teste do original deixaria o comportamento real descoberto: qualquer
# mudança no alfabeto ou no formato passaria despercebida pelas duas pontas.
RSpec.describe PdfHelper, type: :helper do
  describe "generate_qr_code_key" do
    subject(:key) { helper.generate_qr_code_key }

    it "tem dez caracteres partidos por um hífen no meio" do
      expect(key).to match(/\A[^-]{5}-[^-]{5}\z/)
    end

    it "evita caracteres que se confundem na transcrição" do
      # O alfabeto exclui 0/O, 1/I/L, 5/S, U/V e Z/2 de propósito: o código pode
      # ser digitado por uma pessoa lendo o PDF impresso.
      ambiguos = %w[0 O 1 I L 5 S U Z]
      100.times do
        expect(helper.generate_qr_code_key.delete("-").chars & ambiguos).to be_empty
      end
    end

    it "usa apenas o alfabeto declarado" do
      permitidos = "2346789BCDFGHJKMPQRTVWXY".chars
      100.times do
        expect(helper.generate_qr_code_key.delete("-").chars - permitidos).to be_empty
      end
    end

    it "não repete o identificador em uma amostra grande" do
      # Não é teste de aleatoriedade: é a garantia mínima de que o gerador não
      # está preso num valor só, que é como um mock mal escrito se comportaria.
      expect(200.times.map { helper.generate_qr_code_key }.uniq.size).to be > 190
    end
  end

  describe "qrcode_signature" do
    it "sorteia de novo quando o identificador já existe" do
      # O laço de unicidade em PdfHelper#qrcode_signature nunca foi exercitado.
      # Aqui o primeiro sorteio colide com um Report existente e o segundo não.
      user = FactoryBot.create(:user)
      FactoryBot.create(:report, user: user, identifier: "AAAAA-BBBBB")

      allow(helper).to receive(:generate_qr_code_key)
        .and_return("AAAAA-BBBBB", "CCCCC-DDDDD")

      pdf = double("pdf")
      expect(pdf).to receive(:print_qr_code) do |data, _options|
        expect(data).to include("CCCCC-DDDDD")
        expect(data).not_to include("AAAAA-BBBBB")
      end

      helper.qrcode_signature(pdf)
    end
  end
end

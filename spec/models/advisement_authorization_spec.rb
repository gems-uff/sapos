# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe AdvisementAuthorization, type: :model do
  it { should be_able_to_be_destroyed }
  let(:professor) { FactoryBot.build(:professor) }
  let(:level) { FactoryBot.build(:level) }
  let(:advisement_authorization) do
    AdvisementAuthorization.new(
      professor: professor,
      level: level,
      start_date: Date.current
    )
  end
  subject { advisement_authorization }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:professor).required(true) }
    it { should belong_to(:level).required(true) }
    it { should validate_presence_of(:start_date) }

    describe "end_date" do
      it "is valid when end_date is after start_date" do
        advisement_authorization.start_date = Date.current
        advisement_authorization.end_date = Date.current + 1.day
        expect(advisement_authorization).to be_valid
      end
      it "is invalid when end_date is before start_date" do
        advisement_authorization.start_date = Date.current
        advisement_authorization.end_date = Date.current - 1.day
        expect(advisement_authorization).to be_invalid
      end
    end

    describe "open periods per professor and level" do
      let(:professor) { FactoryBot.create(:professor) }
      let(:level) { FactoryBot.create(:level) }
      it "does not allow two active authorizations for the same professor and level" do
        FactoryBot.create(:advisement_authorization, professor: professor, level: level, end_date: nil)
        other = FactoryBot.build(:advisement_authorization, professor: professor, level: level, end_date: nil)
        expect(other).to be_invalid
      end
      it "allows a new active authorization once the previous period is closed (re-accreditation)" do
        FactoryBot.create(:advisement_authorization, professor: professor, level: level,
                          start_date: Date.current - 2.days, end_date: Date.current - 1.day)
        other = FactoryBot.build(:advisement_authorization, professor: professor, level: level, end_date: nil)
        expect(other).to be_valid
      end
      it "allows active authorizations for the same professor at different levels" do
        other_level = FactoryBot.create(:level)
        FactoryBot.create(:advisement_authorization, professor: professor, level: level, end_date: nil)
        other = FactoryBot.build(:advisement_authorization, professor: professor, level: other_level, end_date: nil)
        expect(other).to be_valid
      end
      it "does not raise a spurious overlap error when professor and level are blank" do
        # Sem professor/nível, a checagem não deve casar outras linhas em branco:
        # o erro esperado é o de presença, não o de sobreposição. A
        # linha-fantasma (professor/nível nulos) só existe forçando o save sem
        # validação; sem a guarda, `where(professor_id: nil, level_id: nil)` a
        # casaria e o segundo registro em branco herdaria o erro de sobreposição.
        ghost = AdvisementAuthorization.new(professor: nil, level: nil, start_date: Date.current, end_date: nil)
        ghost.save(validate: false)
        other = AdvisementAuthorization.new(professor: nil, level: nil, start_date: Date.current, end_date: nil)
        other.valid?
        expect(other.errors[:base]).not_to include(
          I18n.t("activerecord.errors.models.advisement_authorization.overlapping_authorization")
        )
      end
    end

    # O histórico de um par (professor, nível) é uma sequência de períodos
    # disjuntos, com fim em aberto valendo como infinito. Não basta impedir dois
    # períodos abertos: dois fechados que se cruzam fariam o on_date casar duas
    # linhas para o mesmo par.
    describe "periods that overlap" do
      let(:professor) { FactoryBot.create(:professor) }
      let(:level) { FactoryBot.create(:level) }

      it "rejects a closed period contained in another closed period" do
        FactoryBot.create(
          :advisement_authorization, professor: professor, level: level,
          start_date: Date.new(2020, 1, 1), end_date: Date.new(2021, 1, 1)
        )
        other = FactoryBot.build(
          :advisement_authorization, professor: professor, level: level,
          start_date: Date.new(2020, 6, 1), end_date: Date.new(2020, 9, 1)
        )
        expect(other).to be_invalid
      end

      it "rejects a closed period that straddles the start of an open one" do
        FactoryBot.create(
          :advisement_authorization, professor: professor, level: level,
          start_date: Date.new(2020, 1, 1), end_date: nil
        )
        other = FactoryBot.build(
          :advisement_authorization, professor: professor, level: level,
          start_date: Date.new(2019, 1, 1), end_date: Date.new(2020, 6, 1)
        )
        expect(other).to be_invalid
      end

      # Controle das duas acima: períodos encostados mas disjuntos continuam
      # válidos, senão a validação poderia ser "rejeitar sempre".
      it "accepts consecutive periods that do not overlap" do
        FactoryBot.create(
          :advisement_authorization, professor: professor, level: level,
          start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 12, 31)
        )
        other = FactoryBot.build(
          :advisement_authorization, professor: professor, level: level,
          start_date: Date.new(2021, 1, 1), end_date: nil
        )
        expect(other).to be_valid
      end
    end

    describe "an unparseable de-accreditation date" do
      # Data impossível converte para nil, e o registro salvaria como período
      # aberto: o professor continuaria credenciado, o oposto do que quem
      # digitou queria. Comparar o valor já convertido não enxerga isso; o
      # validates_date reprova a entrada inconvertível.
      ["31/02/2026", "2020", "banana"].each do |entrada|
        it "is rejected instead of silently dropped: #{entrada.inspect}" do
          auth = FactoryBot.build(
            :advisement_authorization, start_date: Date.current - 10.days
          )
          auth.end_date = entrada

          expect(auth.end_date).to be_nil, "o cast já descartou a entrada"
          expect(auth).to be_invalid
        end
      end
    end

    describe "the error message for an end date before the start date" do
      # O Rails prefixa o rótulo do atributo, então a mensagem tem de ser
      # fragmento que completa o rótulo, e não frase inteira que o repete -- a
      # convenção do repositório, como em scholarship_suspension.pt-BR.yml.
      it "names the attribute once" do
        auth = FactoryBot.build(
          :advisement_authorization,
          start_date: Date.current, end_date: Date.current - 1.day
        )
        auth.valid?

        rotulo = AdvisementAuthorization.human_attribute_name(:end_date)
        mensagem = auth.errors.full_messages.first

        # Sem ignorar a caixa a asserção não pega nada: o prefixo do Rails vem
        # capitalizado e a repetição, no meio da frase, vem em minúscula.
        expect(mensagem).to include(rotulo)
        expect(mensagem.scan(/#{Regexp.escape(rotulo)}/i).size).to eq(1)
      end
    end
  end

  describe "Scopes" do
    let(:professor) { FactoryBot.create(:professor) }
    let(:level) { FactoryBot.create(:level) }
    describe "on_date" do
      it "includes an open period already started" do
        auth = FactoryBot.create(:advisement_authorization, professor: professor, level: level,
                                 start_date: Date.current - 1.day, end_date: nil)
        expect(AdvisementAuthorization.on_date(Date.current)).to include(auth)
      end
      it "excludes an open period whose start_date is in the future" do
        # Este é o descasamento que o filtro de vigência corrige: end_date nil
        # não basta; o credenciamento só passa a valer a partir do start_date.
        auth = FactoryBot.create(:advisement_authorization, professor: professor, level: level,
                                 start_date: Date.current + 1.day, end_date: nil)
        expect(AdvisementAuthorization.on_date(Date.current)).not_to include(auth)
      end
      it "includes the end_date day itself (inclusive upper bound)" do
        auth = FactoryBot.create(:advisement_authorization, professor: professor, level: level,
                                 start_date: Date.current - 2.days, end_date: Date.current)
        expect(AdvisementAuthorization.on_date(Date.current)).to include(auth)
      end
      it "excludes a period already closed before the date" do
        auth = FactoryBot.create(:advisement_authorization, professor: professor, level: level,
                                 start_date: Date.current - 2.days, end_date: Date.current - 1.day)
        expect(AdvisementAuthorization.on_date(Date.current)).not_to include(auth)
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        level_name = "AuthorizedLevel"
        advisement_authorization.level = Level.new(name: level_name)
        expect(advisement_authorization.to_label).to eql(level_name)
      end
    end

    describe "active_on?" do
      it "is false when there is no start_date" do
        auth = FactoryBot.build(:advisement_authorization, start_date: nil, end_date: nil)
        expect(auth.active_on?(Date.current)).to be false
      end
      it "is true within an open period (no end_date)" do
        auth = FactoryBot.build(:advisement_authorization, start_date: Date.current - 1.day, end_date: nil)
        expect(auth.active_on?(Date.current)).to be true
      end
      it "is false before the start_date" do
        auth = FactoryBot.build(:advisement_authorization, start_date: Date.current + 1.day, end_date: nil)
        expect(auth.active_on?(Date.current)).to be false
      end
      it "is true within a closed period" do
        auth = FactoryBot.build(:advisement_authorization, start_date: Date.current - 2.days, end_date: Date.current + 2.days)
        expect(auth.active_on?(Date.current)).to be true
      end
      it "is false after the end_date" do
        auth = FactoryBot.build(:advisement_authorization, start_date: Date.current - 2.days, end_date: Date.current - 1.day)
        expect(auth.active_on?(Date.current)).to be false
      end
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# A reconstrução roda uma vez, na migration, sobre o banco como a main o
# deixava: linhas sem datas e o histórico no versions. Os exemplos montam esse
# estado à mão -- a linha viva sem passar pelo paper_trail, e cada versão com o
# instante e o object que se quer --, para controlar a história inteira.
RSpec.describe AdvisementAuthorizationHistory, type: :model do
  let(:professor) { FactoryBot.create(:professor) }
  let(:level) { FactoryBot.create(:level) }
  let(:other_level) { FactoryBot.create(:level) }

  def at(year, month, day)
    Time.zone.local(year, month, day, 12)
  end

  # O início que a main não tinha. A migration só torna a coluna NOT NULL
  # depois da reconstrução, mas o esquema dos testes já é o final: a linha
  # antiga leva esta data, e a reconstrução tem de sobrescrevê-la.
  def undated
    Date.new(1900, 1, 1)
  end

  # Linha como a main a deixava: sem datas, e sem versão de criação.
  def live(professor, level, created_at)
    PaperTrail.request(enabled: false) do
      AdvisementAuthorization.new(professor: professor, level: level, created_at: created_at, start_date: undated)
        .tap { |row| row.save!(validate: false) }
    end
  end

  def version(event, item_id, created_at, object = nil)
    PaperTrail::Version.create!(
      item_type: "AdvisementAuthorization", item_id: item_id, event: event,
      created_at: created_at, object: object
    )
  end

  # O object guarda o estado anterior ao evento, com os instantes em UTC.
  def state(professor_id, level_id, created_at)
    PaperTrail.serializer.dump(
      "professor_id" => professor_id, "level_id" => level_id, "created_at" => created_at
    )
  end

  # Credenciamento criado e removido, como a main fazia ao descredenciar.
  def cycle(item_id, professor, level, from, to)
    version("create", item_id, from)
    version("destroy", item_id, to, state(professor.id, level.id, from.utc))
  end

  def periods(professor, level)
    AdvisementAuthorization.where(professor: professor, level: level)
      .order(:start_date).pluck(:start_date, :end_date)
  end

  def rebuild
    AdvisementAuthorizationHistory.new.rebuild!
  end

  describe "#rebuild!" do
    it "turns a row with no versions into an open period from its creation" do
      live(professor, level, at(2015, 3, 10))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2015, 3, 10), nil]])
    end

    it "turns a create/destroy cycle into a closed period ending on the destroy day" do
      cycle(9001, professor, level, at(2014, 1, 10), at(2016, 5, 20))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2014, 1, 10), Date.new(2016, 5, 20)]])
    end

    # 01:30 em UTC ainda é a noite anterior em Brasília.
    it "takes the day in the application time zone, not in UTC" do
      version("create", 9002, Time.utc(2014, 1, 10, 1, 30))
      version("destroy", 9002, Time.utc(2016, 5, 20, 1, 30),
              state(professor.id, level.id, Time.utc(2014, 1, 10, 1, 30)))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2014, 1, 9), Date.new(2016, 5, 19)]])
    end

    # Linha anterior ao paper_trail não tem create: o início vem do created_at
    # guardado no object. Versão antiga pode guardá-lo com a tag de
    # TimeWithZone, que o app não permite no YAML.
    it "starts a cycle with no create at the created_at kept in the object" do
      version("destroy", 9003, at(2016, 5, 20), state(professor.id, level.id, at(2010, 2, 1)))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2010, 2, 1), Date.new(2016, 5, 20)]])
    end

    it "splits a reused id into one period per cycle" do
      cycle(9004, professor, level, at(2012, 1, 1), at(2013, 1, 1))
      cycle(9004, professor, other_level, at(2015, 6, 1), at(2017, 1, 1))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2012, 1, 1), Date.new(2013, 1, 1)]])
      expect(periods(professor, other_level)).to eq([[Date.new(2015, 6, 1), Date.new(2017, 1, 1)]])
    end

    it "closes a period when an update changes the level, keeping the row on the new one" do
      row = live(professor, other_level, at(2014, 1, 1))
      version("create", row.id, at(2014, 1, 1))
      version("update", row.id, at(2018, 3, 1), state(professor.id, level.id, at(2014, 1, 1).utc))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2014, 1, 1), Date.new(2018, 3, 1)]])
      expect(periods(professor, other_level)).to eq([[Date.new(2018, 3, 1), nil]])
      expect(row.reload.level).to eq(other_level)
    end

    it "merges periods of the same pair up to 30 days apart, but not 31" do
      cycle(9005, professor, level, at(2010, 1, 1), at(2012, 1, 1))
      cycle(9006, professor, level, at(2012, 1, 31), at(2014, 1, 1))
      cycle(9007, professor, other_level, at(2010, 1, 1), at(2012, 1, 1))
      cycle(9008, professor, other_level, at(2012, 2, 1), at(2014, 1, 1))
      rebuild

      expect(periods(professor, level)).to eq([[Date.new(2010, 1, 1), Date.new(2014, 1, 1)]])
      expect(periods(professor, other_level)).to eq([
        [Date.new(2010, 1, 1), Date.new(2012, 1, 1)],
        [Date.new(2012, 2, 1), Date.new(2014, 1, 1)]
      ])
    end

    it "collapses live duplicates of a pair into the oldest row" do
      oldest = live(professor, level, at(2015, 1, 1))
      duplicate = live(professor, level, at(2018, 1, 1))
      history = rebuild

      expect(AdvisementAuthorization.where(professor: professor, level: level).pluck(:id)).to eq([oldest.id])
      expect(periods(professor, level)).to eq([[Date.new(2015, 1, 1), nil]])
      expect(history.removed_duplicates).to eq([duplicate.id])
    end

    # Só a matrícula naquele nível em que o professor é orientador principal
    # recua o início, e só o do primeiro período.
    it "moves the first start back to the first admission advised as main advisor" do
      cycle(9009, professor, level, at(2012, 1, 1), at(2013, 1, 1))
      live(professor, level, at(2016, 1, 1))
      advise(professor, level, Date.new(2011, 3, 1), main: true)
      advise(professor, level, Date.new(2009, 3, 1), main: false)
      advise(professor, other_level, Date.new(2008, 3, 1), main: true)
      rebuild

      expect(periods(professor, level)).to eq([
        [Date.new(2011, 3, 1), Date.new(2013, 1, 1)],
        [Date.new(2016, 1, 1), nil]
      ])
    end

    it "discards a closed period of a level that no longer exists" do
      version("create", 9010, at(2012, 1, 1))
      version("destroy", 9010, at(2013, 1, 1), state(professor.id, 999_999, at(2012, 1, 1).utc))
      history = rebuild

      expect(AdvisementAuthorization.where(level_id: 999_999)).to be_empty
      expect(history.skipped_periods).to eq(1)
    end

    it "reports an unreadable version instead of failing" do
      unreadable = version("destroy", 9011, at(2013, 1, 1), "--- !ruby/object:Object {}\n")
      history = rebuild

      expect(history.unreadable_version_ids).to eq([unreadable.id])
    end

    it "reports a created row with neither a destroy nor a live row" do
      version("create", 9012, at(2015, 1, 1))
      history = rebuild

      expect(history.vanished_item_ids).to eq([9012])
    end

    it "writes no version and leaves every row dated and valid" do
      cycle(9013, professor, level, at(2010, 1, 1), at(2012, 1, 1))
      live(professor, level, at(2016, 1, 1))
      live(professor, other_level, at(2016, 1, 1))

      expect { rebuild }.not_to change(PaperTrail::Version, :count)
      expect(AdvisementAuthorization.where(start_date: undated)).to be_empty
      expect(AdvisementAuthorization.all).to all(be_valid)
    end
  end

  describe "#dismissed_without_accredited_advisor" do
    before(:each) do
      FactoryBot.create(:advisement_authorization, professor: professor, level: level,
                        start_date: Date.new(2010, 1, 1), end_date: Date.new(2015, 12, 31))
    end

    def dismissed(on, advisor: professor)
      enrollment = FactoryBot.create(:enrollment, level: level, admission_date: Date.new(2012, 3, 1))
      advise_enrollment(advisor, enrollment) if advisor
      FactoryBot.create(:dismissal, enrollment: enrollment, date: on) if on
      enrollment
    end

    it "lists only dismissed enrollments with no advisor accredited in the dismissal month" do
      uncovered = dismissed(Date.new(2017, 6, 1))
      dismissed(Date.new(2014, 6, 1))
      # O desligamento só guarda mês e ano: o credenciado a partir do dia 10
      # cobre o aluno que saiu naquele mês.
      later = FactoryBot.create(:professor)
      FactoryBot.create(:advisement_authorization, professor: later, level: level, start_date: Date.new(2017, 6, 10))
      dismissed(Date.new(2017, 6, 1), advisor: later)
      dismissed(Date.new(2017, 6, 1), advisor: nil)
      dismissed(nil)

      expect(AdvisementAuthorizationHistory.new.dismissed_without_accredited_advisor)
        .to contain_exactly(uncovered.id)
    end
  end

  def advise(professor, level, admission_date, main:)
    enrollment = FactoryBot.create(:enrollment, level: level, admission_date: admission_date)
    advise_enrollment(professor, enrollment, main: main)
  end

  # Sem validação: a orientação de interesse aqui é a que já existe no banco,
  # que a regra de credenciamento de hoje não precisa aceitar.
  def advise_enrollment(professor, enrollment, main: true)
    FactoryBot.build(:advisement, professor: professor, enrollment: enrollment, main_advisor: main)
      .tap { |advisement| advisement.save!(validate: false) }
  end
end

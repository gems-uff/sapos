# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionProcessRanking, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:ranking_config).required(true) }
  it { should belong_to(:admission_process).required(true) }
  it { should belong_to(:admission_phase).required(false) }

  before(:each) do
    @ranking_config = FactoryBot.create(:ranking_config, default_column: "Col1")
    @admission_process = FactoryBot.create(:admission_process)
    @admission_phase = FactoryBot.create(:admission_phase)
    @admission_process_phase = FactoryBot.create(:admission_process_phase, admission_process: @admission_process, admission_phase: @admission_phase)
  end
  after(:each) do
    @admission_process_phase.delete
    @admission_process.delete
    @admission_phase.delete
    @ranking_config.delete
  end

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_process_ranking) do
    Admissions::AdmissionProcessRanking.new(
      ranking_config: @ranking_config,
      admission_process: @admission_process,
      admission_phase: @admission_phase
    )
  end
  subject { admission_process_ranking }
  describe "Validations" do
    it { should be_valid }
    context "that_phase_is_part_of_the_process" do
      it "should be valid if phase is part of the process" do
        admission_process_ranking.admission_phase = @admission_phase
        expect(admission_process_ranking).to be_valid
      end
      it "should have error if phase is not part of the process" do
        admission_process_ranking.admission_phase = FactoryBot.create(:admission_phase)
        expect(admission_process_ranking).to have_error(:phase_not_in_process).on(:admission_phase)
        admission_process_ranking.admission_phase = @admission_phase
      end
      it "should be valid if phase is nil" do
        admission_process_ranking.admission_phase = nil
        expect(admission_process_ranking).not_to have_error(:phase_not_in_process).on(:admission_phase)
      end
      it "should be valid if process is nil" do
        admission_process_ranking.admission_process = nil
        expect(admission_process_ranking).not_to have_error(:phase_not_in_process).on(:admission_phase)
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        @ranking_config.name = "Config"
        @admission_process.name = "Processo"
        @admission_process.year = 2024
        @admission_process.semester = 2
        expect(admission_process_ranking.to_label).to eq("Config - Processo (2024.2)")
      end
    end
    describe "generate_ranking" do
      it "assigns positions according to ranking columns" do
        candidates = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: ["10", "1", "3"],
          columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
          destroy_later: @destroy_later
        )
        ranked_candidates = admission_process_ranking.generate_ranking
        expect(ranked_candidates.size).to eq(candidates.size)
        expect_ranking_positions(@ranking_config, candidates, [1, 3, 2])
      end

      it "assigns positions according to ranking columns (with ties)" do
        candidates = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: ["10", "1", "10"],
          columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
          destroy_later: @destroy_later
        )
        ranked_candidates = admission_process_ranking.generate_ranking
        expect(ranked_candidates.size).to eq(candidates.size)
        expect_ranking_positions(@ranking_config, candidates, [1, 3, 1])
      end

      it "uses the second column to break ties" do
        candidates = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: [
            { Col1: "10", Col2: "1" },
            { Col1: "1", Col2: "2" },
            { Col1: "10", Col2: "3" }
          ],
          columns: [
            { name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER },
            { name: "Col2", order: Admissions::RankingColumn::ASC, type: Admissions::FormField::NUMBER }
          ],
          destroy_later: @destroy_later
        )
        ranked_candidates = admission_process_ranking.generate_ranking
        expect(ranked_candidates.size).to eq(candidates.size)
        expect_ranking_positions(@ranking_config, candidates, [1, 3, 2])
      end

      it "generate_ranking with processes and vacancies" do
        m1 = FactoryBot.create(:ranking_machine, name: "M1")
        m2 = FactoryBot.create(:ranking_machine, name: "M2")
        @destroy_later << m1 << m2
        processes = [
          { vacancies: 1, group: nil, order: 1, step: 1, ranking_machine: m1 },
          { vacancies: 1, group: nil, order: 2, step: 1, ranking_machine: m2 }
        ]
        candidates = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: [
            { Col1: "10", Col2: "1" },
            { Col1: "1", Col2: "2" },
            { Col1: "10", Col2: "3" }
          ],
          columns: [
            { name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER },
            { name: "Col2", order: Admissions::RankingColumn::ASC, type: Admissions::FormField::NUMBER }
          ],
          processes: processes,
          destroy_later: @destroy_later
        )
        ranked_candidates = admission_process_ranking.generate_ranking
        expect(ranked_candidates.size).to eq(candidates.size)
        expect_ranking_positions(@ranking_config, candidates, [1, nil, 2])
        expect_ranking_machines(@ranking_config, candidates, ["M1", nil, "M2"])
      end

      describe "generate_ranking with two groups and step ordering" do
        before(:each) do
          @destroy_later << FactoryBot.create(:form_field, name: "racial")
          @destroy_later << FactoryBot.create(:form_field, name: "pcd")

          @general_group = FactoryBot.create(:ranking_group, ranking_config: @ranking_config, name: "general", vacancies: 3)
          pcd_group = FactoryBot.create(:ranking_group, ranking_config: @ranking_config, name: "pcd", vacancies: 1)
          @destroy_later << @general_group << pcd_group

          @ac_machine = FactoryBot.create(:ranking_machine, name: "AC")
          @racial_machine = FactoryBot.create(:ranking_machine, name: "Racial")
          @pcd_machine = FactoryBot.create(:ranking_machine, name: "PCD")
          @destroy_later << @ac_machine << @racial_machine << @pcd_machine

          @racial_machine.form_condition = FactoryBot.create(
            :form_condition,
            mode: Admissions::FormCondition::CONDITION,
            field: "racial",
            condition: Admissions::FormCondition::EQUALS,
            value: "1"
          )
          @racial_machine.save!
          @pcd_machine.form_condition = FactoryBot.create(
            :form_condition,
            mode: Admissions::FormCondition::CONDITION,
            field: "pcd",
            condition: Admissions::FormCondition::EQUALS,
            value: "1"
          )
          @pcd_machine.save!
          @destroy_later << @racial_machine.form_condition << @pcd_machine.form_condition
        end
        it "assigns candidates to processes according to groups and vacancies" do
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "90", racial: "1", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 2, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 2, 3, 4])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "PCD", "AC/2"])
        end

        it "stops at the number of vacancies" do
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "90", racial: "1", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "0", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 2, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 2, 3, 4, nil, nil])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "PCD", "AC/2", nil, nil])
        end

        it "considers different ranking machines" do
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "90", racial: "1", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 2, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 2, 3, nil, nil, 4])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "PCD", nil, nil, "Racial"])
        end

        it "goes through different ranking steps" do
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "90", racial: "0", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 1, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 4, 2, nil, nil, 3])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC/2", "PCD", nil, nil, "Racial"])
        end

        it "considers the order before assigning positions" do
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "1", pcd: "1" },
              { Col1: "90", racial: "0", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 1, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 4, 2, nil, nil, 3])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC/2", "PCD", nil, nil, "Racial"])
        end

        it "counts ties on the first position in a group" do
          @general_group.update!(vacancies: 4)
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "1", pcd: "1" },
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 3, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 1, 3, nil, nil, 4])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "AC", nil, nil, "Racial"])
        end

        it "counts ties on the second position in a group" do
          @general_group.update!(vacancies: 4)
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "1", pcd: "1" },
              { Col1: "90", racial: "0", pcd: "0" },
              { Col1: "90", racial: "0", pcd: "1" },
              { Col1: "70", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 3, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 2, 2, nil, nil, 4])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "AC", nil, nil, "Racial"])
        end

        it "counts ties on the third position in a group" do
          @general_group.update!(vacancies: 4)
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "1", pcd: "1" },
              { Col1: "90", racial: "0", pcd: "0" },
              { Col1: "80", racial: "0", pcd: "1" },
              { Col1: "80", racial: "0", pcd: "0" },
              { Col1: "60", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 3, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 2, 3, 3, nil, 5])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "AC", "AC", nil, "Racial"])
        end

        it "counts ties when almost everyone is tied up" do
          @general_group.update!(vacancies: 4)
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "1", pcd: "1" },
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "100", racial: "0", pcd: "1" },
              { Col1: "100", racial: "1", pcd: "0" },
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" }
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 3, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 1, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 1, 1, 1, 1, 6])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "AC", "AC", "AC", "Racial"])
        end

        it "counts ties when almost everyone is tied up but stops if it consumes all vacancies" do
          @general_group.update!(vacancies: 5)
          candidates = create_ranked_candidates(
            admission_process: @admission_process,
            ranking_config: @ranking_config,
            values: [
              { Col1: "100", racial: "1", pcd: "1" },
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "100", racial: "0", pcd: "1" },
              { Col1: "100", racial: "1", pcd: "0" },
              { Col1: "100", racial: "0", pcd: "0" },
              { Col1: "50", racial: "1", pcd: "0" },
              { Col1: "40", racial: "0", pcd: "0" },
              { Col1: "30", racial: "0", pcd: "0" },
              { Col1: "20", racial: "1", pcd: "0" },
              { Col1: "10", racial: "1", pcd: "0" },
              { Col1: "0", racial: "0", pcd: "0" },
            ],
            columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
            processes: [
              { vacancies: 3, group: "general", order: 1, step: 1, ranking_machine: @ac_machine },
              { vacancies: 2, group: "general", order: 2, step: 1, ranking_machine: @racial_machine },
              { vacancies: 1, group: "pcd", order: 3, step: 1, ranking_machine: @pcd_machine },
              { vacancies: nil, group: "general", order: 4, step: 2, ranking_machine: @ac_machine }
            ],
            destroy_later: @destroy_later
          )

          ranked_candidates = admission_process_ranking.generate_ranking
          expect(ranked_candidates.size).to eq(candidates.size)
          expect_ranking_positions(@ranking_config, candidates, [1, 1, 1, 1, 1, 6, nil, nil, 7, nil, nil])
          expect_ranking_machines(@ranking_config, candidates, ["AC", "AC", "AC", "AC", "AC", "Racial", nil, nil, "Racial", nil, nil])
        end
      end
    end
    describe "set_candidate_position" do
      it "updates candidate metadata and persists ranking result fields" do
        candidate_app = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: ["10"],
          columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
          destroy_later: @destroy_later
        ).first

        process = @ranking_config.ranking_processes.first
        ranking_result = Admissions::AdmissionRankingResult.find_or_create_by(
          admission_application_id: candidate_app.id,
          ranking_config_id: @ranking_config.id
        )

        candidate = {
          __position: nil,
          __machine: nil,
          __process: nil,
          __ranking_result: ranking_result
        }

        admission_process_ranking.set_candidate_position(candidate, process, 7, "AC")

        expect(candidate[:__position]).to eq(7)
        expect(candidate[:__machine]).to eq("AC")
        expect(candidate[:__process]).to eq(process)

        ranking_result.reload
        expect(ranking_result.filled_position.value.to_i).to eq(7)
        expect(ranking_result.filled_machine.value).to eq("AC")
        expect(ranking_result.filled_form.is_filled).to eq(true)
      end
    end
    describe "filter_sort_candidates" do
      it "filters candidates by precondition and sorts by ranking columns" do
        eligible_field = FactoryBot.create(:form_field, name: "eligible")
        condition = FactoryBot.create(
          :form_condition,
          mode: Admissions::FormCondition::CONDITION,
          field: "eligible",
          condition: Admissions::FormCondition::EQUALS,
          value: "1"
        )
        @destroy_later << eligible_field << condition
        @ranking_config.update!(form_condition: condition)

        candidates = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: [
            { Col1: "50", eligible: "1" },
            { Col1: "90", eligible: "0" },
            { Col1: "70", eligible: "1" }
          ],
          columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
          destroy_later: @destroy_later
        )

        result = admission_process_ranking.filter_sort_candidates(
          @ranking_config.ranking_columns.all,
          @admission_process.admission_applications
        )

        expect(result.size).to eq(2)
        expect(result.map { |r| r["Col1"] }).to eq([70.0, 50.0])
        expect(result.map { |r| r[:__candidate].id }).to eq([candidates[2].id, candidates[0].id])
      end

      it "skips candidates that do not have all ranking fields" do
        candidates = create_ranked_candidates(
          admission_process: @admission_process,
          ranking_config: @ranking_config,
          values: [
            { Col1: "10" },
            { Col2: "99" },
            { Col1: "30" }
          ],
          columns: [{ name: "Col1", order: Admissions::RankingColumn::DESC, type: Admissions::FormField::NUMBER }],
          destroy_later: @destroy_later
        )

        result = admission_process_ranking.filter_sort_candidates(
          @ranking_config.ranking_columns.all,
          @admission_process.admission_applications
        )

        expect(result.size).to eq(2)
        expect(result.map { |r| r[:__candidate].id }).to eq([candidates[2].id, candidates[0].id])
      end
    end
    describe "compare_candidates" do
      it "uses the first column when values differ" do
        columns = [
          Admissions::RankingColumn.new(name: "Col1", order: Admissions::RankingColumn::DESC),
          Admissions::RankingColumn.new(name: "Col2", order: Admissions::RankingColumn::ASC)
        ]

        first = { "Col1" => 100.0, "Col2" => 9.0 }
        second = { "Col1" => 90.0, "Col2" => 1.0 }

        comparison = Admissions::AdmissionProcessRanking.compare_candidates(columns, first, second)
        expect(comparison).to be < 0
      end

      it "uses the second column as tie-breaker when first column is tied" do
        columns = [
          Admissions::RankingColumn.new(name: "Col1", order: Admissions::RankingColumn::DESC),
          Admissions::RankingColumn.new(name: "Col2", order: Admissions::RankingColumn::ASC)
        ]

        first = { "Col1" => 100.0, "Col2" => 1.0 }
        second = { "Col1" => 100.0, "Col2" => 3.0 }

        comparison = Admissions::AdmissionProcessRanking.compare_candidates(columns, first, second)
        expect(comparison).to be < 0
      end

      it "returns zero when all compared columns are tied" do
        columns = [
          Admissions::RankingColumn.new(name: "Col1", order: Admissions::RankingColumn::DESC),
          Admissions::RankingColumn.new(name: "Col2", order: Admissions::RankingColumn::ASC)
        ]

        first = { "Col1" => 100.0, "Col2" => 2.0 }
        second = { "Col1" => 100.0, "Col2" => 2.0 }

        comparison = Admissions::AdmissionProcessRanking.compare_candidates(columns, first, second)
        expect(comparison).to eq(0)
      end
    end
  end
end

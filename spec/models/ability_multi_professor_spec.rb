# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

RSpec.describe Ability, type: :model do
  def user_for(role_id, professor: nil)
    user = User.new(actual_role: role_id)
    user.professor = professor
    user
  end

  def ability_for(role_id, **kwargs)
    Ability.new(user_for(role_id, **kwargs))
  end

  describe "professor com a turma de muitos professores" do
    before(:each) do
      @professor = FactoryBot.create(:professor)
      @other_professor = FactoryBot.create(:professor)
      @course = FactoryBot.create(:course)
    end

    subject(:ability) { ability_for(Role::ROLE_PROFESSOR, professor: @professor) }

    # Persistida: o accessible_by mede SQL, e registro em memoria nao aparece.
    def turma_com(*professors, year:, semester:)
      FactoryBot.create(
        :course_class, course: @course, professors: professors,
        year: year, semester: semester
      )
    end

    before(:each) do
      current = YearSemester.current
      @own_class = turma_com(@professor, year: current.year, semester: current.semester)
      @own_old_class = turma_com(@professor, year: current.year - 1, semester: 1)
      @other_class = turma_com(@other_professor, year: current.year, semester: current.semester)
      # O caso da issue: turma dividida entre os dois.
      @shared_class = turma_com(
        @professor, @other_professor, year: current.year, semester: current.semester
      )
    end

    context "quando permite todos os semestres" do
      before(:each) do
        allow(CustomVariable).to receive(:professor_login_can_post_grades)
          .and_return("yes_all_semesters")
      end

      it "lanca nota nas turmas proprias, em qualquer semestre" do
        expect(ability).to be_able_to(:post_grades, @own_class)
        expect(ability).to be_able_to(:post_grades, @own_old_class)
        expect(ability).to be_able_to(:read_pendencies, @own_class)
        expect(ability).to be_able_to(
          :post_grades, ClassEnrollment.new(course_class: @own_class)
        )
      end

      it "nao lanca nota em turma de outro professor" do
        expect(ability).not_to be_able_to(:post_grades, @other_class)
        expect(ability).not_to be_able_to(
          :post_grades, ClassEnrollment.new(course_class: @other_class)
        )
      end

      it "lanca nota na turma dividida com outro professor" do
        expect(ability).to be_able_to(:post_grades, @shared_class)
        expect(ability).to be_able_to(:update, @shared_class)
        expect(ability).to be_able_to(:read_pendencies, @shared_class)
        expect(ability).to be_able_to(
          :post_grades, ClassEnrollment.new(course_class: @shared_class)
        )
      end

      it "da ao outro professor da turma dividida as mesmas permissoes" do
        outra = ability_for(Role::ROLE_PROFESSOR, professor: @other_professor)
        expect(outra).to be_able_to(:post_grades, @shared_class)
        expect(outra).not_to be_able_to(:post_grades, @own_class)
      end

      # accessible_by e o caminho que a lista do active_scaffold usa; ele nao
      # passa pelo mesmo codigo da checagem de instancia.
      it "enxerga as turmas proprias na consulta, sem repetir a dividida" do
        ids = CourseClass.accessible_by(ability, :post_grades).pluck(:id)
        expect(ids).to match_array(
          [@own_class.id, @own_old_class.id, @shared_class.id]
        )
      end
    end

    context "quando permite so o semestre corrente" do
      before(:each) do
        allow(CustomVariable).to receive(:professor_login_can_post_grades)
          .and_return("yes")
      end

      it "lanca nota so na turma propria do semestre corrente" do
        expect(ability).to be_able_to(:post_grades, @own_class)
        expect(ability).to be_able_to(:post_grades, @shared_class)
        expect(ability).not_to be_able_to(:post_grades, @own_old_class)
        expect(ability).not_to be_able_to(:post_grades, @other_class)
      end

      it "enxerga na consulta so as turmas do semestre corrente" do
        ids = CourseClass.accessible_by(ability, :post_grades).pluck(:id)
        expect(ids).to match_array([@own_class.id, @shared_class.id])
      end
    end

    context "quando nao permite" do
      before(:each) do
        allow(CustomVariable).to receive(:professor_login_can_post_grades)
          .and_return("no")
      end

      it "le a turma e nao escreve nada" do
        expect(ability).to be_able_to(:read, @shared_class)
        expect(ability).not_to be_able_to(:post_grades, @shared_class)
        expect(ability).not_to be_able_to(:update, @shared_class)
        expect(ability).not_to be_able_to(:read_pendencies, @shared_class)
      end
    end
  end
end

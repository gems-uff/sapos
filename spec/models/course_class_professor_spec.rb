# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CourseClassProfessor, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:course_class).required(true) }
  it { should belong_to(:professor).required(true) }

  let(:course_class) { FactoryBot.build(:course_class) }
  let(:professor) { FactoryBot.build(:professor) }

  subject(:course_class_professor) do
    CourseClassProfessor.new(
      course_class: course_class,
      professor: professor
    )
  end

  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:course_class) }
    it { should validate_presence_of(:professor) }

    it do
      should validate_uniqueness_of(:professor_id)
        .scoped_to(:course_class_id)
        .with_message(:taken)
    end
  end

  describe "#to_label" do
    it "returns the professor and course class labels" do
      professor.name = "Bia"
      course_class.name = "Turma A"

      expect(course_class_professor.to_label).to eq(
        "#{professor.to_label} - #{course_class.to_label}"
      )
    end
  end
end

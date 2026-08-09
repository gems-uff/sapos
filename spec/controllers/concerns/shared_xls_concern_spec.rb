# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe SharedXlsConcern, type: :concern do
  include SharedXlsConcern

  describe "parse_rows_xlsx" do
    let(:course_type) { FactoryBot.create(:course_type, has_score: true) }
    let(:course) { FactoryBot.create(:course, course_type: course_type) }
    let(:course_class) { FactoryBot.create(:course_class, course: course) }
    let(:enrollment1) { FactoryBot.create(:enrollment, enrollment_number: "101") }
    let(:enrollment2) { FactoryBot.create(:enrollment, enrollment_number: "102") }
    let(:class_enrollment1) do
      FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment1, grade: 87, situation: ClassEnrollment::APPROVED)
    end
    let(:class_enrollment2) do
      FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment2, grade: nil)
    end

    let(:xlsx_file) do
      tempfile = Tempfile.new(["test", ".xlsx"])
      tempfile.binmode
      tempfile.write(render_course_classes_summary_xls([class_enrollment1, class_enrollment2]))
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: "test.xlsx")
    end

    it "returns a hash with enrollment numbers as keys" do
      result = parse_rows_xls(xlsx_file)
      expect(result).to be_a(Hash)
      expect(result.keys).to include("101", "102")
    end

    it "returns the grade value for filled cells" do
      result = parse_rows_xls(xlsx_file)
      expect(result["101"][:grade]).to eq("8.7")
    end

    it "returns nil for empty grade cells" do
      result = parse_rows_xls(xlsx_file)
      expect(result["102"][:grade]).to be_nil
    end

    it "raises ArgumentError for a non-upload object" do
      expect { parse_rows_xls("not a file") }.to raise_error(ArgumentError, "Invalid upload")
    end

    it "raises ArgumentError for an invalid file extension" do
      tempfile = Tempfile.new(["test", ".txt"])
      invalid_file = ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: "test.txt")
      expect { parse_rows_xls(invalid_file) }.to raise_error(ArgumentError, "Invalid file name")
    end
  end
end

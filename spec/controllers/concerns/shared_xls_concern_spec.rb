# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

RSpec.describe SharedXlsConcern, type: :concern do
  include SharedXlsConcern

  describe "parse_grades_xlsx" do
    let(:enrollment1) { FactoryBot.build(:enrollment, enrollment_number: "101") }
    let(:enrollment2) { FactoryBot.build(:enrollment, enrollment_number: "102") }
    let(:class_enrollment1) { FactoryBot.build(:class_enrollment, enrollment: enrollment1, grade: 87) }
    let(:class_enrollment2) { FactoryBot.build(:class_enrollment, enrollment: enrollment2, grade: nil) }

    let(:xlsx_file) do
      tempfile = Tempfile.new(["test", ".xlsx"])
      tempfile.binmode
      tempfile.write(render_course_classes_summary_xls([class_enrollment1, class_enrollment2]))
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(tempfile: tempfile,filename: "test.xlsx")
    end

    it "returns a hash with enrollment numbers as keys" do
      result = parse_grades_xlsx(xlsx_file)
      expect(result).to be_a(Hash)
      expect(result.keys).to include("101", "102")
    end

    it "returns the grade value for filled cells" do
      result = parse_grades_xlsx(xlsx_file)
      expect(result["101"]).to eq("8.7")
    end

    it "returns nil for empty grade cells" do
      result = parse_grades_xlsx(xlsx_file)
      expect(result["102"]).to be_nil
    end
  end
end
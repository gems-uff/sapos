require "spec_helper"

describe YearSemester do
  let(:year_semester) { YearSemester.new }
  let(:current_year) { Date.today.year }
  subject { year_semester }
  describe "Methods" do
    describe "on_date" do
      context "should return the first semester of the current year when" do
        it "date is between first semester begin and second semester begin" do
          date = Date.parse("#{current_year}/#{YearSemester::FIRST_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY + 1}")
          year_semester = YearSemester.on_date(date)
          year_semester.semester.should eql(YearSemester::FIRST_SEMESTER)
          year_semester.year.should eql(Date.today.year)
        end
      end
      context "should return the second semester of the current year when" do
        it "date is after second semester begin" do
          date = Date.parse("#{current_year}/#{YearSemester::SECOND_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY + 1}")
          year_semester = YearSemester.on_date(date)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(current_year)
        end
      end
      context "should return the second semester of the last year when" do
        it "date is before first semester begin" do
          date = Date.parse("#{current_year}/#{YearSemester::FIRST_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY}") - 1.day
          year_semester = YearSemester.on_date(date)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(current_year - 1)
        end
      end
    end
    describe "semester_begin" do
      context "should return date of the first semester begin when" do
        it "semester is set to first semester" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::FIRST_SEMESTER
          date = Date.parse("#{current_year}/#{YearSemester::FIRST_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY}")
          year_semester.semester_begin.should eql(date)
        end
      end
      context "should return the second semester of the current year when" do

        it "date is after second semester begin" do
          pending "Fazer =)"
          date = Date.parse("#{Date.today.year}/#{YearSemester::SECOND_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY + 1}")
          year_semester = YearSemester.on_date(date)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(Date.today.year)
        end
      end
      context "should return the second semester of the last year when" do
        it "date is before first semester begin" do
          pending "Fazer =)"
          date = Date.parse("#{Date.today.year}/#{YearSemester::FIRST_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY}") - 1.day
          year_semester = YearSemester.on_date(date)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(Date.today.year - 1)
        end
      end
    end
    describe "current" do
      it "should return the year semester on today's date" do
        year_semester = YearSemester.on_date(Date.today)
        current_year_semester = YearSemester.current
        year_semester.semester.should eql(current_year_semester.semester)
        year_semester.year.should eql(current_year_semester.year)
      end
    end
  end
end
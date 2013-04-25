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
          date = Date.parse("#{current_year}/#{YearSemester::SECOND_SEMESTER_BEGIN_MONTH}/#{YearSemester::SECOND_SEMESTER_BEGIN_DAY + 1}")
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
      context "should return date of the second semester begin when" do
        it "date is after second semester begin" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          date = Date.parse("#{current_year}/#{YearSemester::SECOND_SEMESTER_BEGIN_MONTH}/#{YearSemester::SECOND_SEMESTER_BEGIN_DAY}")
          year_semester.semester_begin.should eql(date)
        end
      end
    end
    describe "semester_end" do
      it "should return date of the first semester end" do
        year_semester.year = current_year
        year_semester.semester = YearSemester::FIRST_SEMESTER
        date = Date.parse("#{current_year}/#{YearSemester::SECOND_SEMESTER_BEGIN_MONTH}/#{YearSemester::SECOND_SEMESTER_BEGIN_DAY}") - 1.day
        year_semester.semester_end.should eql(date)
      end
    end
    describe "next_semester_start" do
      context "should return date of the next semester start when" do
        it "semester is set to first semester" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::FIRST_SEMESTER
          date = Date.parse("#{current_year}/#{YearSemester::SECOND_SEMESTER_BEGIN_MONTH}/#{YearSemester::SECOND_SEMESTER_BEGIN_DAY}")
          year_semester.next_semester_start.should eql(date)
        end
        it "semester is set to second semester" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          date = Date.parse("#{current_year + 1}/#{YearSemester::FIRST_SEMESTER_BEGIN_MONTH}/#{YearSemester::FIRST_SEMESTER_BEGIN_DAY}")
          year_semester.next_semester_start.should eql(date)
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
    describe "opposite_semester" do
      it "should return first semester when semester is set to second" do
        year_semester.semester = YearSemester::SECOND_SEMESTER
        year_semester.opposite_semester.should eql(YearSemester::FIRST_SEMESTER)
      end
      it "should return second semester when semester is set to first" do
        year_semester.semester = YearSemester::FIRST_SEMESTER
        year_semester.opposite_semester.should eql(YearSemester::SECOND_SEMESTER)
      end
    end
    describe "toggle_semester" do
      it "should switch to first semester when semester is set to second" do
        year_semester.semester = YearSemester::SECOND_SEMESTER
        year_semester.toggle_semester
        year_semester.semester.should eql(YearSemester::FIRST_SEMESTER)
      end
    end
    describe "decrease_semesters" do
      context "should return the expected YearSemester when" do
        it "semester is set to first and the parameter is even" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::FIRST_SEMESTER
          year_semester.decrease_semesters(2)
          year_semester.semester.should eql(YearSemester::FIRST_SEMESTER)
          year_semester.year.should eql(current_year - 1)
        end
        it "semester is set to first and the parameter is odd" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::FIRST_SEMESTER
          year_semester.decrease_semesters(3)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(current_year - 2)
        end
        it "semester is set to second and the parameter is even" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          year_semester.decrease_semesters(2)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(current_year - 1)
        end
        it "semester is set to second and the parameter is odd" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          year_semester.decrease_semesters(3)
          year_semester.semester.should eql(YearSemester::FIRST_SEMESTER)
          year_semester.year.should eql(current_year - 1)
        end
        it "the parameter is negative" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          expected = year_semester + 3
          year_semester.decrease_semesters(-3)
          year_semester.semester.should eql(expected.semester)
          year_semester.year.should eql(expected.year)
        end
      end
    end
    describe "increase_semesters" do
      context "should return the expected YearSemester when" do
        it "semester is set to first and the parameter is even" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::FIRST_SEMESTER
          year_semester.increase_semesters(2)
          year_semester.semester.should eql(YearSemester::FIRST_SEMESTER)
          year_semester.year.should eql(current_year + 1)
        end
        it "semester is set to first and the parameter is odd" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::FIRST_SEMESTER
          year_semester.increase_semesters(3)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(current_year + 1)
        end
        it "semester is set to second and the parameter is even" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          year_semester.increase_semesters(2)
          year_semester.semester.should eql(YearSemester::SECOND_SEMESTER)
          year_semester.year.should eql(current_year + 1)
        end
        it "semester is set to second and the parameter is odd" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          year_semester.increase_semesters(3)
          year_semester.semester.should eql(YearSemester::FIRST_SEMESTER)
          year_semester.year.should eql(current_year + 2)
        end
        it "the parameter is negative" do
          year_semester.year = current_year
          year_semester.semester = YearSemester::SECOND_SEMESTER
          expected = year_semester - 3
          year_semester.increase_semesters(-3)
          year_semester.semester.should eql(expected.semester)
          year_semester.year.should eql(expected.year)
        end
      end
    end
  end
end
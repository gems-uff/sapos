# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CustomVariable, type: :model do
  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:custom_variable) do
    CustomVariable.new(
      variable: "single_advisor_points"
    )
  end
  let(:default_from) { ActionMailer::Base.default[:from]}
  subject { custom_variable }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:variable) }
  end

  describe "Methods" do
    context "single_advisor_points" do
      it "should return 1.0 when there is no variable defined" do
        config = CustomVariable.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?

        expect(CustomVariable.single_advisor_points).to eq(1.0)
      end

      it "should return 2.0 when it is defined to 2.0" do
        config = CustomVariable.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :single_advisor_points, value: "2.0")

        expect(CustomVariable.single_advisor_points).to eq(2.0)
      end
    end

    context "multiple_advisor_points" do
      it "should return 0.5 when there is no variable defined" do
        config = CustomVariable.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?

        expect(CustomVariable.multiple_advisor_points).to eq(0.5)
      end

      it "should return 2.0 when it is defined to 2.0" do
        config = CustomVariable.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :multiple_advisor_points, value: "2.0")

        expect(CustomVariable.multiple_advisor_points).to eq(2.0)
      end
    end

    context "identity_issuing_country" do
      it "should return '' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?

        expect(CustomVariable.identity_issuing_country).to eq("")
      end

      it "should return 'Brasil' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :identity_issuing_country, value: "Brasil")

        expect(CustomVariable.identity_issuing_country).to eq("Brasil")
      end
    end

    context "class_schedule_text" do
      it "should return '' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:class_schedule_text)
        config.delete unless config.nil?

        expect(CustomVariable.class_schedule_text).to eq("")
      end

      it "should return 'bla' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:class_schedule_text)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :class_schedule_text, value: "bla")

        expect(CustomVariable.class_schedule_text).to eq("bla")
      end
    end

    context "redirect_email" do
      it "should return nil when there is no variable defined" do
        config = CustomVariable.find_by_variable(:redirect_email)
        config.delete unless config.nil?

        expect(CustomVariable.redirect_email).to eq(nil)
      end

      it "should return '' when the value is nil" do
        config = CustomVariable.find_by_variable(:redirect_email)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :redirect_email, value: nil)

        expect(CustomVariable.redirect_email).to eq("")
      end

      it "should return 'bla' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:redirect_email)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :redirect_email, value: "bla")

        expect(CustomVariable.redirect_email).to eq("bla")
      end
    end

    context "reply_to" do
      it "should return default value when there is no variable defined" do
        config = CustomVariable.find_by_variable(:reply_to)
        config.delete unless config.nil?

        expect(CustomVariable.reply_to).to eq(default_from)
      end

      it "should return default value when the value is nil" do
        config = CustomVariable.find_by_variable(:reply_to)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :reply_to, value: nil)

        expect(CustomVariable.reply_to).to eq(default_from)
      end

      it "should return value when the values is defined" do
        config = CustomVariable.find_by_variable(:reply_to)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :reply_to, value: "email@email.com.br")

        expect(CustomVariable.reply_to).to eq("email@email.com.br")
      end
    end

    context "notification_footer" do
      it "should return '' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:notification_footer)
        config.delete unless config.nil?

        expect(CustomVariable.notification_footer).to eq("")
      end

      it "should return 'bla' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:notification_footer)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :notification_footer, value: "bla")

        expect(CustomVariable.notification_footer).to eq("bla")
      end
    end

    context "instance_name" do
      it "should return nil when there is no variable defined" do
        config = CustomVariable.find_by_variable(:instance_name)
        config.delete unless config.nil?

        expect(CustomVariable.instance_name).to eq(nil)
      end

      it "should return 'Computacao' when it is defined to Computacao" do
        config = CustomVariable.find_by_variable(:instance_name)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :instance_name, value: "Computacao")

        expect(CustomVariable.instance_name).to eq("Computacao")
      end
    end

    context "minimum grade for approval" do
      it "should return 60 when there is no variable defined" do
        config = CustomVariable.find_by_variable(:minimum_grade_for_approval)
        config.delete unless config.nil?

        expect(CustomVariable.minimum_grade_for_approval).to eq(60)
      end

      it "should return 60 when the value is blank" do
        config = CustomVariable.find_by_variable(:minimum_grade_for_approval)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :minimum_grade_for_approval, value: "")

        expect(CustomVariable.minimum_grade_for_approval).to eq(60)
      end

      it "should return 70 when it is defined to 7.0" do
        config = CustomVariable.find_by_variable(:minimum_grade_for_approval)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :minimum_grade_for_approval, value: "7.0")

        expect(CustomVariable.minimum_grade_for_approval).to eq(70)
      end
    end

    context "grade of disapproval for absence" do
      it "should return nil when there is no variable defined" do
        config = CustomVariable.find_by_variable(:grade_of_disapproval_for_absence)
        config.delete unless config.nil?

        expect(CustomVariable.grade_of_disapproval_for_absence).to eq(nil)
      end

      it "should return nil when the value is blank" do
        config = CustomVariable.find_by_variable(:grade_of_disapproval_for_absence)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :grade_of_disapproval_for_absence, value: "")

        expect(CustomVariable.grade_of_disapproval_for_absence).to eq(nil)
      end

      it "should return 50 when it is defined to 5.0" do
        config = CustomVariable.find_by_variable(:grade_of_disapproval_for_absence)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :grade_of_disapproval_for_absence, value: "5.0")

        expect(CustomVariable.grade_of_disapproval_for_absence).to eq(50)
      end
    end

    context "professor login can post grades" do
      it "should return 'no' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:professor_login_can_post_grades)
        config.delete unless config.nil?

        expect(CustomVariable.professor_login_can_post_grades).to eq("no")
      end

      it "should return 'no' when value is nil" do
        config = CustomVariable.find_by_variable(:professor_login_can_post_grades)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :professor_login_can_post_grades, value: nil)

        expect(CustomVariable.professor_login_can_post_grades).to eq("no")
      end

      it "should return 'yes' when it is defined to yes" do
        config = CustomVariable.find_by_variable(:professor_login_can_post_grades)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :professor_login_can_post_grades, value: "yes")

        expect(CustomVariable.professor_login_can_post_grades).to eq("yes")
      end

      it "should return 'yes_all_semesters' when it is defined to yes_all_semesters" do
        config = CustomVariable.find_by_variable(:professor_login_can_post_grades)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :professor_login_can_post_grades, value: "yes_all_semesters")

        expect(CustomVariable.professor_login_can_post_grades).to eq("yes_all_semesters")
      end
    end

    context "month year range" do
      it "should return default [20, 10, false] when there is no variable defined" do
        config = CustomVariable.find_by_variable(:month_year_range)
        config.delete unless config.nil?

        expect(CustomVariable.month_year_range).to eq([20, 10, false])
      end

      it "should return [5, 5, false] when it is defined to '5:5'" do
        config = CustomVariable.find_by_variable(:month_year_range)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :month_year_range, value: "5:5")

        expect(CustomVariable.month_year_range).to eq([5, 5, false])
      end

      it "should return [3, 3, true] when it is defined to '~3'" do
        config = CustomVariable.find_by_variable(:month_year_range)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :month_year_range, value: "~3")

        expect(CustomVariable.month_year_range).to eq([3, 3, true])
      end
    end

    context "year semester range" do
      it "should return default [20, 1, true] when there is no variable defined" do
        config = CustomVariable.find_by_variable(:year_semester_range)
        config.delete unless config.nil?

        expect(CustomVariable.year_semester_range).to eq([20, 1, true])
      end

      it "should return [10, 5, false] when it is defined to '10:5'" do
        config = CustomVariable.find_by_variable(:year_semester_range)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :year_semester_range, value: "10:5")

        expect(CustomVariable.year_semester_range).to eq([10, 5, false])
      end
    end

    context "past calendar range" do
      it "should return default hash when there is no variable defined" do
        config = CustomVariable.find_by_variable(:past_calendar_range)
        config.delete unless config.nil?

        result = CustomVariable.past_calendar_range
        expect(result).to be_a(Hash)
        expect(result).to have_key("minDate")
        expect(result).to have_key("maxDate")
      end

      it "should return a hash with minDate and maxDate when defined" do
        config = CustomVariable.find_by_variable(:past_calendar_range)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :past_calendar_range, value: "5:2")

        result = CustomVariable.past_calendar_range
        expect(result["minDate"]).to eq("-5Y")
        expect(result["maxDate"]).to eq("+2Y")
      end
    end

    context "academic calendar range" do
      it "should return default hash when there is no variable defined" do
        config = CustomVariable.find_by_variable(:academic_calendar_range)
        config.delete unless config.nil?

        result = CustomVariable.academic_calendar_range
        expect(result).to be_a(Hash)
        expect(result).to have_key("minDate")
        expect(result).to have_key("maxDate")
      end

      it "should return a hash with minDate and maxDate when defined" do
        config = CustomVariable.find_by_variable(:academic_calendar_range)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :academic_calendar_range, value: "3:1")

        result = CustomVariable.academic_calendar_range
        expect(result["minDate"]).to eq("-3Y")
        expect(result["maxDate"]).to eq("+1Y")
      end
    end

    context "quadrennial period" do
      it "should return 'Not defined' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:quadrennial_period)
        config.delete unless config.nil?

        expect(CustomVariable.quadrennial_period).to eq("Not defined")
      end

      it "should return '2021-2024' when it is defined to 2021-2024" do
        config = CustomVariable.find_by_variable(:quadrennial_period)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create!(variable: :quadrennial_period, value: "2021-2024")

        expect(CustomVariable.quadrennial_period).to eq("2021-2024")
      end
    end
  end
end

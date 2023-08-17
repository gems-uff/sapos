# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

RSpec.describe Notification, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:notification_logs) }
  it { should have_many(:notification_params).dependent(:destroy).class_name("NotificationParam") }
  it { should have_many(:params).dependent(:destroy).class_name("NotificationParam").conditions(active: true) }

  before(:all) do
    @destroy_later = []
    @query = FactoryBot.create(:query)
  end
  after(:all) do
    @query.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:notification) do
    @destroy_later << notification = FactoryBot.create(:notification, query: @query)
    notification
  end
  subject { notification }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:query).inverse_of(:notifications).required(true) }
    it { should validate_presence_of(:body_template).on(:update) }
    it { should validate_inclusion_of(:frequency).in_array(Notification::FREQUENCIES).on(:update) }
    it { should validate_presence_of(:frequency).on(:update) }
    it { should validate_presence_of(:notification_offset).on(:update) }
    it { should validate_presence_of(:query_offset).on(:update) }
    it { should validate_presence_of(:subject_template).on(:update) }
    it { should validate_presence_of(:to_template).on(:update) }

    describe "notification_offset" do
      context "should have error when" do
        it "frequency is 'manual' and notification_offset is different of '0'" do
          notification.frequency = Notification::MANUAL
          notification.notification_offset = "1"
          expect(notification).to have_error(:manual_frequency_requires_notification_offset_to_be_zero).on :notification_offset
        end
      end
    end

    describe "has_grades_report_pdf_attachment" do
      context "should be valid when" do
        it "email is individual and query has enrollments_id column alias" do
          notification.has_grades_report_pdf_attachment = true
          notification.sql_query = "SELECT ENROLLMENTS.ID AS enrollments_id FROM ENROLLMENTS"
          notification.individual = true
          expect(notification).to have(0).errors_on :has_grades_report_pdf_attachment
        end
      end

      context "should have error when" do
        it "email individual is not individual" do
          notification.has_grades_report_pdf_attachment = true
          notification.sql_query = "SELECT ENROLLMENTS.ID AS enrollments_id FROM ENROLLMENTS"
          notification.individual = false
          expect(notification).to have_error(:individual_required).on :has_grades_report_pdf_attachment
        end

        it "query has not enrollments_id column alias" do
          notification.has_grades_report_pdf_attachment = true
          notification.sql_query = "SELECT ENROLLMENTS.ID FROM ENROLLMENTS"
          notification.individual = true
          expect(notification).to have_error(:query_with_enrollments_id_alias_column_required).on :has_grades_report_pdf_attachment
        end
        it "email is not individual and query has not enrollments_id column alias" do
          notification.has_grades_report_pdf_attachment = true
          notification.sql_query = "SELECT ENROLLMENTS.ID FROM ENROLLMENTS"
          notification.individual = false
          expect(notification).to have(2).errors_on :has_grades_report_pdf_attachment
        end
      end
    end
  end

  describe "Methods" do
    describe "calculate_next_notification_date" do
      describe "for daily frequency" do
        it "should be 01/04 if today is 01/03" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::DAILY
          expect(notification.calculate_next_notification_date(time: Time.parse("01/03"))).to eq(Time.parse("01/04"))
        end
      end

      describe "for weekly frequency" do
        it "should be 2014/01/20(monday) if today is 2014/01/14(tuesday)" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::WEEKLY
          expect(notification.calculate_next_notification_date(time: Time.parse("2014/01/14"))).to eq(Time.parse("2014/01/20"))
        end

        it "should be 2014/01/16(thursday) if today is 2014/01/14(tuesday) and offset is 3" do
          notification = FactoryBot.create(:notification, notification_offset: "3")
          notification.frequency = Notification::WEEKLY
          expect(notification.calculate_next_notification_date(time: Time.parse("2014/01/14"))).to eq(Time.parse("2014/01/16"))
        end

        it "should be 2014/01/18(saturday) if today is 2014/01/14(tuesday) and offset is -2" do
          notification = FactoryBot.create(:notification, notification_offset: "-2")
          notification.frequency = Notification::WEEKLY
          expect(notification.calculate_next_notification_date(time: Time.parse("2014/01/14"))).to eq(Time.parse("2014/01/18"))
        end

        it "should be 2014/02/01(saturday) if today is 2014/01/25(saturday) and offset is -2" do
          notification = FactoryBot.create(:notification, notification_offset: "-2")
          notification.frequency = Notification::WEEKLY
          expect(notification.calculate_next_notification_date(time: Time.parse("2014/01/25"))).to eq(Time.parse("2014/02/01"))
        end
      end

      describe "for monthly frequency" do
        it "should be 02/01 if today is 01/17" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::MONTHLY
          expect(notification.calculate_next_notification_date(time: Time.parse("01/17"))).to eq(Time.parse("02/01"))
        end

        it "should be 02/15 if today is 01/17 and offset is 14" do
          notification = FactoryBot.create(:notification, notification_offset: "14")
          notification.frequency = Notification::MONTHLY
          expect(notification.calculate_next_notification_date(time: Time.parse("01/17"))).to eq(Time.parse("02/15"))
        end

        it "should be 02/08 if today is 01/17 and offset is 1w" do
          notification = FactoryBot.create(:notification, notification_offset: "1w")
          notification.frequency = Notification::MONTHLY
          expect(notification.calculate_next_notification_date(time: Time.parse("01/17"))).to eq(Time.parse("02/08"))
        end
      end

      describe "for semiannual frequency" do
        it "should be 03/01 of this year if today is 09/01 of last year" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::SEMIANNUAL
          expect(notification.calculate_next_notification_date(time: Time.parse("09/01") - 1.year)).to eq(Time.parse("03/01"))
        end

        it "should be 03/01 of this year if today is 02/01" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::SEMIANNUAL
          expect(notification.calculate_next_notification_date(time: Time.parse("02/01"))).to eq(Time.parse("03/01"))
        end

        it "should be 08/01 if today is 04/01" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::SEMIANNUAL
          expect(notification.calculate_next_notification_date(time: Time.parse("04/01"))).to eq(Time.parse("08/01"))
        end

        it "should be 03/01 of next year if today is 09/01" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::SEMIANNUAL
          expect(notification.calculate_next_notification_date(time: Time.parse("09/01"))).to eq((Time.parse("03/01") + 1.year))
        end

        it "should be 07/01 if today is 02/15 and offset is -31" do
          notification = FactoryBot.create(:notification, notification_offset: "-31")
          notification.frequency = Notification::SEMIANNUAL
          expect(notification.calculate_next_notification_date(time: Time.parse("02/15"))).to eq(Time.parse("07/01"))
        end
      end

      describe "for annual frequency" do
        it "should be 2015/01/01 if today is 2014/06/27" do
          notification = FactoryBot.create(:notification)
          notification.frequency = Notification::ANNUAL
          expect(notification.calculate_next_notification_date(time: Time.parse("2014/06/27"))).to eq(Time.parse("2015/01/01"))
        end
      end
    end
  end
end

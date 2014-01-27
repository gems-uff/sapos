# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe Configuration do
  let(:configuration) { Configuration.new }
  subject { configuration }
  describe "Validations" do
    describe "variable" do
      context "should be valid when" do
        it "variable is not null" do
          configuration.variable = "variable"
          configuration.should have(0).errors_on :variable
        end
      end
      context "should have error blank when" do
        it "variable is null" do
          configuration.variable = nil
          configuration.should have_error(:blank).on :variable
        end
      end
    end
  end

  describe "Methods" do
    context "single_advisor_points" do
      it "should return 1.0 when there is no configuration defined" do
        config = Configuration.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?

        Configuration.single_advisor_points.should == 1.0
      end

      it "should return 2.0 when it is defined to 2.0" do
        config = Configuration.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        Configuration.create(:variable=>:single_advisor_points, :value=>"2.0")

        Configuration.single_advisor_points.should == 2.0
      end
    end

    context "multiple_advisor_points" do
      it "should return 0.5 when there is no configuration defined" do
        config = Configuration.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?

        Configuration.multiple_advisor_points.should == 0.5
      end

      it "should return 2.0 when it is defined to 2.0" do
        config = Configuration.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        Configuration.create(:variable=>:multiple_advisor_points, :value=>"2.0")

        Configuration.multiple_advisor_points.should == 2.0
      end
    end 

    context "program_level" do
      it "should return nil when there is no configuration defined" do
        config = Configuration.find_by_variable(:program_level)
        config.delete unless config.nil?

        Configuration.program_level.should == nil
      end

      it "should return 5 when it is defined to 5" do
        config = Configuration.find_by_variable(:program_level)
        config.delete unless config.nil?
        Configuration.create(:variable=>:program_level, :value=>"5")

        Configuration.program_level.should == 5
      end
    end 

    context "identity_issuing_country" do
      it "should return nil when there is no configuration defined and no country named Brasil" do
        country = Country.find_by_name("Brasil")
        country.delete unless country.nil?

        config = Configuration.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?

        Configuration.identity_issuing_country.should == nil
      end

      it "should return Brasil when there is no configuration, but there is a country named Brasil" do
        country = Country.find_by_name("Brasil")
        country.delete unless country.nil?
        country = FactoryGirl.create(:country, :name => "Brasil")

        config = Configuration.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?
        
        Configuration.identity_issuing_country.should == country
      end

      it "should return England it is defined to England" do
        brasil = Country.find_by_name("Brasil")
        brasil.delete unless brasil.nil?
        FactoryGirl.create(:country, :name => "Brasil")

        england = Country.find_by_name("England")
        england.delete unless england.nil?
        england = FactoryGirl.create(:country, :name => "England")

        config = Configuration.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?

        Configuration.create(:variable => :identity_issuing_country, :value=>"England")

        Configuration.identity_issuing_country.should == england
      end
    end 

    context "notification_frequency" do
      it "should return 1d when there is no configuration defined" do
        config = Configuration.find_by_variable(:notification_frequency)
        config.delete unless config.nil?

        Configuration.notification_frequency.should == "1d"
      end

      it "should return 5m when it is defined to 5m" do
        config = Configuration.find_by_variable(:notification_frequency)
        config.delete unless config.nil?
        Configuration.create(:variable=>:notification_frequency, :value=>"5m")

        Configuration.notification_frequency.should == "5m"
      end
    end 

    context "notification_start_at" do
      it "should return 12:00 when there is no configuration defined" do
        config = Configuration.find_by_variable(:notification_start_at)
        config.delete unless config.nil?

        Configuration.notification_start_at.should == "12:00"
      end

      it "should return 18:00 when it is defined to 18:00" do
        config = Configuration.find_by_variable(:notification_start_at)
        config.delete unless config.nil?
        Configuration.create(:variable=>:notification_start_at, :value=>"18:00")

        Configuration.notification_start_at.should == "18:00"
      end
    end

    context "class_schedule_text" do
      it "should return '' when there is no configuration defined" do
        config = Configuration.find_by_variable(:class_schedule_text)
        config.delete unless config.nil?

        Configuration.class_schedule_text.should == ''
      end

      it "should return 'bla' when it is defined to bla" do
        config = Configuration.find_by_variable(:class_schedule_text)
        config.delete unless config.nil?
        Configuration.create(:variable=>:class_schedule_text, :value=>"bla")

        Configuration.class_schedule_text.should == 'bla'
      end
    end 

     context "redirect_email" do
      it "should return 'sapos@mailinator.com' when there is no configuration defined" do
        config = Configuration.find_by_variable(:redirect_email)
        config.delete unless config.nil?

        Configuration.redirect_email.should == 'sapos@mailinator.com'
      end

      it "should return 'bla' when it is defined to bla" do
        config = Configuration.find_by_variable(:redirect_email)
        config.delete unless config.nil?
        Configuration.create(:variable=>:redirect_email, :value=>"bla")

        Configuration.redirect_email.should == 'bla'
      end
    end 
  end

end

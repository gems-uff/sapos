# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe CustomVariable do
  let(:custom_variable) { CustomVariable.new }
  subject { custom_variable }
  describe "Validations" do
    describe "variable" do
      context "should be valid when" do
        it "variable is not null" do
          custom_variable.variable = "variable"
          expect(custom_variable).to have(0).errors_on :variable
        end
      end
      context "should have error blank when" do
        it "variable is null" do
          custom_variable.variable = nil
          expect(custom_variable).to have_error(:blank).on :variable
        end
      end
    end
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
        CustomVariable.create(:variable=>:single_advisor_points, :value=>"2.0")

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
        CustomVariable.create(:variable=>:multiple_advisor_points, :value=>"2.0")

        expect(CustomVariable.multiple_advisor_points).to eq(2.0)
      end
    end 

    context "program_level" do
      it "should return nil when there is no variable defined" do
        config = CustomVariable.find_by_variable(:program_level)
        config.delete unless config.nil?

        expect(CustomVariable.program_level).to eq(nil)
      end

      it "should return 5 when it is defined to 5" do
        config = CustomVariable.find_by_variable(:program_level)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:program_level, :value=>"5")

        expect(CustomVariable.program_level).to eq(5)
      end
    end 

    context "identity_issuing_country" do
      it "should return nil when there is no variable defined and no country named Brasil" do
        country = Country.find_by_name("Brasil")
        country.delete unless country.nil?

        config = CustomVariable.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?

        expect(CustomVariable.identity_issuing_country).to eq(nil)
      end

      it "should return Brasil when there is no variable, but there is a country named Brasil" do
        country = Country.find_by_name("Brasil")
        country.delete unless country.nil?
        country = FactoryBot.create(:country, :name => "Brasil")

        config = CustomVariable.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?
        
        expect(CustomVariable.identity_issuing_country).to eq(country)
      end

      it "should return England it is defined to England" do
        brasil = Country.find_by_name("Brasil")
        brasil.delete unless brasil.nil?
        FactoryBot.create(:country, :name => "Brasil")

        england = Country.find_by_name("England")
        england.delete unless england.nil?
        england = FactoryBot.create(:country, :name => "England")

        config = CustomVariable.find_by_variable(:identity_issuing_country)
        config.delete unless config.nil?

        CustomVariable.create(:variable => :identity_issuing_country, :value=>"England")

        expect(CustomVariable.identity_issuing_country).to eq(england)
      end
    end 

    context "class_schedule_text" do
      it "should return '' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:class_schedule_text)
        config.delete unless config.nil?

        expect(CustomVariable.class_schedule_text).to eq('')
      end

      it "should return 'bla' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:class_schedule_text)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:class_schedule_text, :value=>"bla")

        expect(CustomVariable.class_schedule_text).to eq('bla')
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
        CustomVariable.create(:variable=>:redirect_email, :value=>nil)

        expect(CustomVariable.redirect_email).to eq('')
      end

      it "should return 'bla' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:redirect_email)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:redirect_email, :value=>"bla")

        expect(CustomVariable.redirect_email).to eq('bla')
      end
    end

    context "notification_footer" do
      it "should return '' when there is no variable defined" do
        config = CustomVariable.find_by_variable(:notification_footer)
        config.delete unless config.nil?

        expect(CustomVariable.notification_footer).to eq('')
      end

      it "should return 'bla' when it is defined to bla" do
        config = CustomVariable.find_by_variable(:notification_footer)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:notification_footer, :value=>"bla")

        expect(CustomVariable.notification_footer).to eq('bla')
      end
    end
  
  end

end

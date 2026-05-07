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
  end
end

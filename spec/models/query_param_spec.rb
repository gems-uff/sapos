# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryParam, type: :model do
  let(:query) { FactoryBot.build(:query) }
  let(:query_param) do
    QueryParam.new(
      query: query,
      value_type: "String",
      name: "_var",
    )
  end
  subject { query_param }
  context "Validations" do
    it { should be_valid }
    it { should belong_to(:query).required(true) }
    it { should validate_inclusion_of(:value_type).in_array(QueryParam::VALUE_TYPES) }
    it { should validate_presence_of(:value_type) }
    it { should validate_presence_of(:name) }
    it do
      should_not allow_value(
        "A", "_", " ", "0", "Za", "9z", " ",
        "a|\\<>,.:;?/ç^~{}[]'`'\"!@#$%&*()-+= 	\t\n\r"
      ).for(:name).with_message(:invalid_name)
    end
    it do
      should allow_value(
        "aa", "zA", "a9", "z0", "a_", "_a", "_z",
        "_0", "_9", "__", "aA_z0", "_aZ9_"
      ).for(:name).with_message(:invalid_name)
    end
    context "default_value is incompatible with value_type" do
      it "show an integer error on default_value" do
        query_param.value_type = "Integer"
        should_not allow_value(
          " ", "a", "0.0", "1.0", "0.1", "-1.0", ".0",
          ".1", ",0", ",1", "1,0"
        ).for(:default_value).with_message(:invalid_integer)
      end
      it "show an float error on default_value" do
        query_param.value_type = "Float"
        should_not allow_value(
          " ", "a", ".", ",", "1,0", "0,0", "0,1", "1,000"
        ).for(:default_value).with_message(:invalid_float)
      end
      it "show an time error on default_value" do
        query_param.value_type = "Time"
        should_not allow_value(
          " ", "a", "1", "24:01", "25:00", "22:60", "22:50:61"
        ).for(:default_value).with_message(:invalid_time)
      end
      it "show an date error on default_value" do
        query_param.value_type = "Date"
        should_not allow_value(
          " ", "a", "1", "32/12/2019", "30/13/2019",
          "29/02/2019", "20193112"
        ).for(:default_value).with_message(:invalid_date)
      end
      it "show an date_time error on default_value" do
        query_param.value_type = "DateTime"
        should_not allow_value(
          " ", "a", "1", "32/12/2019 20:21:22", "30/13/2019 20:21:22",
          "15/12/2010 24:21:22", "15/12/2010 23:60:22", "15/12/2010 23:30:61"
        ).for(:default_value).with_message(:invalid_date_time)
      end
    end
    context "default_value is compatible with value_type" do
      it "do not have string error in default_value" do
        query_param.value_type = "String"
        should allow_value(
          " ", "a", "1", " Qualquer String 1234 "
        ).for(:default_value)
      end
      it "do not have literal error in default_value" do
        query_param.value_type = "Literal"
        should allow_value(
          "ab",
        ).for(:default_value)
      end
      it "do not have list error in default_value" do
        query_param.value_type = "List"
        should allow_value(
          " Qualquer String para lista 1234 ,, ,,, ,a,b,123, ",
        ).for(:default_value)
      end
      it "do not have invalid_integer error in default_value" do
        query_param.value_type = "Integer"
        should allow_value(
          "0", "+0", "-0", "01", "1", "2", "-1", "+1",
          "99999999", "-99999999"
        ).for(:default_value).with_message(:invalid_integer)
      end
      it "do not have invalid_float error in default_value" do
        query_param.value_type = "Float"
        should allow_value(
          "0", "+0", "-0", "01", "1", "2", "-1", "+1",
          "99999999", "-99999999",
          ".0", ".1", "-.0", "-.1", "0.0", "0.1", "10.01", "-10.01",
          "9999.9999", "-9999.9999", "+9999.9999"
        ).for(:default_value).with_message(:invalid_float)
      end
      it "do not have invalid_time error in default_value" do
        query_param.value_type = "Time"
        should allow_value(
          "11:50", "11:50:30", "23:59:59", "23:59"
        ).for(:default_value).with_message(:invalid_time)
      end
      it "do not have invalid_date error in default_value" do
        query_param.value_type = "Date"
        should allow_value(
          "31/12/2019", "31-12-2019", "20191231", "29/02/2020"
        ).for(:default_value).with_message(:invalid_date)
      end
      it "do not have invalid_date_time error in default_value" do
        query_param.value_type = "DateTime"
        should allow_value(
          "31/12/2018 10:11", "31/12/2018-10:11", "31/12/2018;10:11",
          "31/12/2018 10:11:53", "20191225202122"
        ).for(:default_value).with_message(:invalid_date_time)
      end
    end
  end
end

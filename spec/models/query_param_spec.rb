# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe QueryParam do

  let(:query_param) {QueryParam.new}
  subject { query_param }

  context "creating or updating" do

    context "name is blank" do
      it "show an blank error on name" do
	query_param.name = nil     
        query_param.should have_error(:blank).on :name
      end
    end

    context "name is invalid" do
      it "show an format error on name" do
	query_param.name = "A"
        query_param.should have_error(:invalid_name).on :name

	query_param.name = "_"
        query_param.should have_error(:invalid_name).on :name

	query_param.name = " "
        query_param.should have_error(:invalid_name).on :name

        query_param.name = "0"
        query_param.should have_error(:invalid_name).on :name

        query_param.name = "Za"
        query_param.should have_error(:invalid_name).on :name

        query_param.name = "9z"
        query_param.should have_error(:invalid_name).on :name

	query_param.name = "a|\\<>,.:;?/ç^~{}[]'`'\"!@#$%&*()-+= 	\t\n\r"
        query_param.should have_error(:invalid_name).on :name

      end
    end

    context "name is valid" do
      it "do not have errors on name" do
	query_param.name = "aa"
        query_param.should have(0).errors_on :name

	query_param.name = "zA"
        query_param.should have(0).errors_on :name

	query_param.name = "a9"
        query_param.should have(0).errors_on :name

        query_param.name = "z0"
        query_param.should have(0).errors_on :name

	query_param.name = "a_"
        query_param.should have(0).errors_on :name

        query_param.name = "_a"
        query_param.should have(0).errors_on :name

        query_param.name = "_z"
        query_param.should have(0).errors_on :name

	query_param.name = "_0"
        query_param.should have(0).errors_on :name

	query_param.name = "_9"
        query_param.should have(0).errors_on :name

        query_param.name = "__"
        query_param.should have(0).errors_on :name

	query_param.name = "aA_z0"
        query_param.should have(0).errors_on :name

        query_param.name = "_aZ9_"
        query_param.should have(0).errors_on :name
      end
    end

    context "value_type is blank" do
      it "show an blank error on value_type" do
        query_param.value_type = nil      
        query_param.should have_error(:blank).on :value_type
      end
    end

    context "value_type is invalid" do
      it "show an inclusion error on value_type" do
        query_param.value_type = "tipo_invalido"
        query_param.should have_error(:inclusion).on :value_type
      end
    end

    context "value_type is valid" do
      it "do not have errors in value_type" do

     	query_param.value_type = "String"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "Integer"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "Float"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "List"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "Date"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "DateTime"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "Time"
        query_param.should have(0).errors_on :value_type

     	query_param.value_type = "Literal"
        query_param.should have(0).errors_on :value_type

      end	      
    end

    context "default_value is incompatible with value_type" do
     it "show an integer error on default_value" do
       query_param.value_type = "Integer"

       query_param.default_value = " "
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = "a"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = "0.0"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = "1.0"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = "0.1"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = "-1.0"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = ".0"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = ".1"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = ",0" 
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = ",1"
       query_param.should have_error(:invalid_integer).on :default_value

       query_param.default_value = "1,0" 
       query_param.should have_error(:invalid_integer).on :default_value
     end

     it "show an float error on default_value" do
       query_param.value_type = "Float"

       query_param.default_value = " "
       query_param.should have_error(:invalid_float).on :default_value

       query_param.default_value = "a"
       query_param.should have_error(:invalid_float).on :default_value
 
       query_param.default_value = "."
       query_param.should have_error(:invalid_float).on :default_value

       query_param.default_value = ","
       query_param.should have_error(:invalid_float).on :default_value

       query_param.default_value = "1,0"
       query_param.should have_error(:invalid_float).on :default_value

       query_param.default_value = "0,0"
       query_param.should have_error(:invalid_float).on :default_value

       query_param.default_value = "0,1"
       query_param.should have_error(:invalid_float).on :default_value

       query_param.default_value = "1,000"
       query_param.should have_error(:invalid_float).on :default_value
     end

     it "show an time error on default_value" do
       query_param.value_type = "Time"

       query_param.default_value = " "
       query_param.should have_error(:invalid_time).on :default_value

       query_param.default_value = "a"
       query_param.should have_error(:invalid_time).on :default_value

       query_param.default_value = "1"
       query_param.should have_error(:invalid_time).on :default_value

       query_param.default_value = "24:01"
       query_param.should have_error(:invalid_time).on :default_value

       query_param.default_value = "25:00"
       query_param.should have_error(:invalid_time).on :default_value

       query_param.default_value = "22:60"
       query_param.should have_error(:invalid_time).on :default_value

       query_param.default_value = "22:50:61"
       query_param.should have_error(:invalid_time).on :default_value
     end

     it "show an date error on default_value" do
       query_param.value_type = "Date"

       query_param.default_value = " "
       query_param.should have_error(:invalid_date).on :default_value

       query_param.default_value = "a"
       query_param.should have_error(:invalid_date).on :default_value

       query_param.default_value = "1"
       query_param.should have_error(:invalid_date).on :default_value

       query_param.default_value = "32/12/2019"
       query_param.should have_error(:invalid_date).on :default_value

       query_param.default_value = "30/13/2019"
       query_param.should have_error(:invalid_date).on :default_value

       query_param.default_value = "29/02/2019"
       query_param.should have_error(:invalid_date).on :default_value

       query_param.default_value = "20193112"
       query_param.should have_error(:invalid_date).on :default_value
     end

     it "show an date_time error on default_value" do
       query_param.value_type = "DateTime"

       query_param.default_value = " "
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "a"
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "1"
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "32/10/2010 20:21:22"
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "30/13/2010 20:21:22"
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "15/12/2010 24:21:22"
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "15/12/2010 23:60:22"
       query_param.should have_error(:invalid_date_time).on :default_value

       query_param.default_value = "15/12/2010 23:30:61"
       query_param.should have_error(:invalid_date_time).on :default_value
     end

    end

    context "default_value is compatible with value_type" do
      it "do not have errors in default_value" do
        query_param.value_type = "String"
       
	query_param.default_value = " "
        query_param.should have(0).errors_on :default_value	

        query_param.default_value = " Qualquer String 1234 "
        query_param.should have(0).errors_on :default_value

        query_param.value_type = "Literal"
       
	query_param.default_value = " "
        query_param.should have(0).errors_on :default_value	

        query_param.default_value = " Qualquer Literal 1234 "
        query_param.should have(0).errors_on :default_value

	query_param.value_type = "List"

	query_param.default_value = " "
        query_param.should have(0).errors_on :default_value

        query_param.default_value = " Qualquer String para lista 1234 ,, ,,, ,a,b,123, "
        query_param.should have(0).errors_on :default_value

	query_param.value_type = "Integer"

	query_param.default_value = "0"
        query_param.should have(0).errors_on :default_value

        query_param.default_value = "+0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "01"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "+1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "99999999"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-99999999"
        query_param.should have(0).errors_on :default_value

        query_param.value_type = "Float"
       
	query_param.default_value = "0"
        query_param.should have(0).errors_on :default_value	

        query_param.default_value = "+0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "+1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = ".0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = ".1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-.0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-.1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "0.0"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "0.1"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "10.01"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-10.01"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "9999.9999"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "-9999.9999"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "+9999.9999"
        query_param.should have(0).errors_on :default_value

        query_param.value_type = "Time"
       
	query_param.default_value = "11:50"
        query_param.should have(0).errors_on :default_value	

        query_param.default_value = "11:50:30"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "23:59:59"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "23:59"
        query_param.should have(0).errors_on :default_value
	
        query_param.value_type = "Date"

	query_param.default_value = "31/12/2019"
        query_param.should have(0).errors_on :default_value

        query_param.default_value = "31-12-2019"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "20191231"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "29/02/2020"
        query_param.should have(0).errors_on :default_value

        query_param.value_type = "DateTime"
       
	query_param.default_value = "31/12/2018 10:11"
        query_param.should have(0).errors_on :default_value	

        query_param.default_value = "31/12/2018-10:11"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "31/12/2018;10:11"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "31/12/2018 10:11:53"
        query_param.should have(0).errors_on :default_value

	query_param.default_value = "20191225202122"
        query_param.should have(0).errors_on :default_value
      end	      
    end

  end

end

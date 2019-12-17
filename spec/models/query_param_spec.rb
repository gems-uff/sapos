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
        expect(query_param).to have_error(:blank).on :name
      end
    end

    context "name is invalid" do
      it "show an format error on name" do
	query_param.name = "A"
        expect(query_param).to have_error(:invalid_name).on :name

	query_param.name = "_"
        expect(query_param).to have_error(:invalid_name).on :name

	query_param.name = " "
        expect(query_param).to have_error(:invalid_name).on :name

        query_param.name = "0"
        expect(query_param).to have_error(:invalid_name).on :name

        query_param.name = "Za"
        expect(query_param).to have_error(:invalid_name).on :name

        query_param.name = "9z"
        expect(query_param).to have_error(:invalid_name).on :name

	query_param.name = "a|\\<>,.:;?/ç^~{}[]'`'\"!@#$%&*()-+= 	\t\n\r"
        expect(query_param).to have_error(:invalid_name).on :name

      end
    end

    context "name is valid" do
      it "do not have errors on name" do
	query_param.name = "aa"
        expect(query_param).to have(0).errors_on :name

	query_param.name = "zA"
        expect(query_param).to have(0).errors_on :name

	query_param.name = "a9"
        expect(query_param).to have(0).errors_on :name

        query_param.name = "z0"
        expect(query_param).to have(0).errors_on :name

	query_param.name = "a_"
        expect(query_param).to have(0).errors_on :name

        query_param.name = "_a"
        expect(query_param).to have(0).errors_on :name

        query_param.name = "_z"
        expect(query_param).to have(0).errors_on :name

	query_param.name = "_0"
        expect(query_param).to have(0).errors_on :name

	query_param.name = "_9"
        expect(query_param).to have(0).errors_on :name

        query_param.name = "__"
        expect(query_param).to have(0).errors_on :name

	query_param.name = "aA_z0"
        expect(query_param).to have(0).errors_on :name

        query_param.name = "_aZ9_"
        expect(query_param).to have(0).errors_on :name
      end
    end

    context "value_type is blank" do
      it "show an blank error on value_type" do
        query_param.value_type = nil      
        expect(query_param).to have_error(:blank).on :value_type
      end
    end

    context "value_type is invalid" do
      it "show an inclusion error on value_type" do
        query_param.value_type = "tipo_invalido"
        expect(query_param).to have_error(:inclusion).on :value_type
      end
    end

    context "value_type is valid" do
      it "do not have errors in value_type" do

     	query_param.value_type = "String"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "Integer"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "Float"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "List"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "Date"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "DateTime"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "Time"
        expect(query_param).to have(0).errors_on :value_type

     	query_param.value_type = "Literal"
        expect(query_param).to have(0).errors_on :value_type

      end	      
    end

    context "default_value is incompatible with value_type" do
     it "show an integer error on default_value" do
       query_param.value_type = "Integer"

       query_param.default_value = " "
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = "a"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = "0.0"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = "1.0"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = "0.1"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = "-1.0"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = ".0"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = ".1"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = ",0" 
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = ",1"
       expect(query_param).to have_error(:invalid_integer).on :default_value

       query_param.default_value = "1,0" 
       expect(query_param).to have_error(:invalid_integer).on :default_value
     end

     it "show an float error on default_value" do
       query_param.value_type = "Float"

       query_param.default_value = " "
       expect(query_param).to have_error(:invalid_float).on :default_value

       query_param.default_value = "a"
       expect(query_param).to have_error(:invalid_float).on :default_value
 
       query_param.default_value = "."
       expect(query_param).to have_error(:invalid_float).on :default_value

       query_param.default_value = ","
       expect(query_param).to have_error(:invalid_float).on :default_value

       query_param.default_value = "1,0"
       expect(query_param).to have_error(:invalid_float).on :default_value

       query_param.default_value = "0,0"
       expect(query_param).to have_error(:invalid_float).on :default_value

       query_param.default_value = "0,1"
       expect(query_param).to have_error(:invalid_float).on :default_value

       query_param.default_value = "1,000"
       expect(query_param).to have_error(:invalid_float).on :default_value
     end

     it "show an time error on default_value" do
       query_param.value_type = "Time"

       query_param.default_value = " "
       expect(query_param).to have_error(:invalid_time).on :default_value

       query_param.default_value = "a"
       expect(query_param).to have_error(:invalid_time).on :default_value

       query_param.default_value = "1"
       expect(query_param).to have_error(:invalid_time).on :default_value

       query_param.default_value = "24:01"
       expect(query_param).to have_error(:invalid_time).on :default_value

       query_param.default_value = "25:00"
       expect(query_param).to have_error(:invalid_time).on :default_value

       query_param.default_value = "22:60"
       expect(query_param).to have_error(:invalid_time).on :default_value

       query_param.default_value = "22:50:61"
       expect(query_param).to have_error(:invalid_time).on :default_value
     end

     it "show an date error on default_value" do
       query_param.value_type = "Date"

       query_param.default_value = " "
       expect(query_param).to have_error(:invalid_date).on :default_value

       query_param.default_value = "a"
       expect(query_param).to have_error(:invalid_date).on :default_value

       query_param.default_value = "1"
       expect(query_param).to have_error(:invalid_date).on :default_value

       query_param.default_value = "32/12/2019"
       expect(query_param).to have_error(:invalid_date).on :default_value

       query_param.default_value = "30/13/2019"
       expect(query_param).to have_error(:invalid_date).on :default_value

       query_param.default_value = "29/02/2019"
       expect(query_param).to have_error(:invalid_date).on :default_value

       query_param.default_value = "20193112"
       expect(query_param).to have_error(:invalid_date).on :default_value
     end

     it "show an date_time error on default_value" do
       query_param.value_type = "DateTime"

       query_param.default_value = " "
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "a"
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "1"
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "32/10/2010 20:21:22"
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "30/13/2010 20:21:22"
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "15/12/2010 24:21:22"
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "15/12/2010 23:60:22"
       expect(query_param).to have_error(:invalid_date_time).on :default_value

       query_param.default_value = "15/12/2010 23:30:61"
       expect(query_param).to have_error(:invalid_date_time).on :default_value
     end

    end

    context "default_value is compatible with value_type" do
      it "do not have errors in default_value" do
        query_param.value_type = "String"
       
	query_param.default_value = " "
        expect(query_param).to have(0).errors_on :default_value	

        query_param.default_value = " Qualquer String 1234 "
        expect(query_param).to have(0).errors_on :default_value

        query_param.value_type = "Literal"
       
	query_param.default_value = " "
        expect(query_param).to have(0).errors_on :default_value	

        query_param.default_value = " Qualquer Literal 1234 "
        expect(query_param).to have(0).errors_on :default_value

	query_param.value_type = "List"

	query_param.default_value = " "
        expect(query_param).to have(0).errors_on :default_value

        query_param.default_value = " Qualquer String para lista 1234 ,, ,,, ,a,b,123, "
        expect(query_param).to have(0).errors_on :default_value

	query_param.value_type = "Integer"

	query_param.default_value = "0"
        expect(query_param).to have(0).errors_on :default_value

        query_param.default_value = "+0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "01"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "+1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "99999999"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-99999999"
        expect(query_param).to have(0).errors_on :default_value

        query_param.value_type = "Float"
       
	query_param.default_value = "0"
        expect(query_param).to have(0).errors_on :default_value	

        query_param.default_value = "+0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "+1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = ".0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = ".1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-.0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-.1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "0.0"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "0.1"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "10.01"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-10.01"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "9999.9999"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "-9999.9999"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "+9999.9999"
        expect(query_param).to have(0).errors_on :default_value

        query_param.value_type = "Time"
       
	query_param.default_value = "11:50"
        expect(query_param).to have(0).errors_on :default_value	

        query_param.default_value = "11:50:30"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "23:59:59"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "23:59"
        expect(query_param).to have(0).errors_on :default_value
	
        query_param.value_type = "Date"

	query_param.default_value = "31/12/2019"
        expect(query_param).to have(0).errors_on :default_value

        query_param.default_value = "31-12-2019"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "20191231"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "29/02/2020"
        expect(query_param).to have(0).errors_on :default_value

        query_param.value_type = "DateTime"
       
	query_param.default_value = "31/12/2018 10:11"
        expect(query_param).to have(0).errors_on :default_value	

        query_param.default_value = "31/12/2018-10:11"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "31/12/2018;10:11"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "31/12/2018 10:11:53"
        expect(query_param).to have(0).errors_on :default_value

	query_param.default_value = "20191225202122"
        expect(query_param).to have(0).errors_on :default_value
      end	      
    end

  end

end

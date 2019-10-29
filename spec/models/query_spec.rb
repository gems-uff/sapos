# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe Query do

  let(:query) {Query.new}
  subject { query }
  context "creating or updating" do

    context "name is blank" do
      it "show an blank error on name" do
	query.name = nil     
        expect(query).to have_error(:blank).on :name
      end
    end
    context "sql is blank" do
      it "show an blank error on sql" do
        query.sql = ""      
        expect(query).to have_error(:blank).on :sql
      end
    end
  end

end

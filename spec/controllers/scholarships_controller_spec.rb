# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe ScholarshipsController do

  describe "Search" do

    describe "condition_for_available_column" do

      it "should include the scholarship if there is no allocation, end_date is nil and search date is after start_date" do
        scholarship = FactoryGirl.create(:scholarship, :start_date => Date.parse("2012/01/01"), :end_date => nil)
        condition = ScholarshipsController.condition_for_available_column(:available, {:use => 'yes', :month => "2", :year => "2013"}, "")
        Scholarship.where(condition.map(&:to_sql).join(' OR ')).should include(scholarship)
      end

      it "should not include the scholarship if there is no allocation, end_date is nil and search date is before start_date" do
        scholarship = FactoryGirl.create(:scholarship, :start_date => Date.parse("2012/01/01"), :end_date => nil)
        condition = ScholarshipsController.condition_for_available_column(:available, {:use => 'yes', :month => "2", :year => "2011"}, "")
        Scholarship.where(condition.map(&:to_sql).join(' OR ')).should_not include(scholarship)
      end

      it "should not include the scholarship if there is no allocation, search date is after end_date" do
        scholarship = FactoryGirl.create(:scholarship, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2015/01/31"))
        condition = ScholarshipsController.condition_for_available_column(:available, {:use => 'yes', :month => "2", :year => "2016"}, "")
        Scholarship.where(condition.map(&:to_sql).join(' OR ')).should_not include(scholarship)
      end

      it "should include the scholarship if there is allocation, but it ends before the search date" do
        scholarship = FactoryGirl.create(:scholarship, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2015/01/31"))
        FactoryGirl.create(:scholarship_duration, :scholarship_id => scholarship.id, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2013/01/31"), :cancel_date => nil)
        condition = ScholarshipsController.condition_for_available_column(:available, {:use => 'yes', :month => "2", :year => "2013"}, "")
        Scholarship.where(condition.map(&:to_sql).join(' OR ')).should include(scholarship)
      end

      it "should not include the scholarship if there is allocation, and it ends after the search date" do
        scholarship = FactoryGirl.create(:scholarship, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2015/01/31"))
        FactoryGirl.create(:scholarship_duration, :scholarship_id => scholarship.id, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2013/03/31"), :cancel_date => nil)
        condition = ScholarshipsController.condition_for_available_column(:available, {:use => 'yes', :month => "2", :year => "2013"}, "")
        Scholarship.where(condition.map(&:to_sql).join(' OR ')).should_not include(scholarship)
      end

      it "should include the scholarship if there is allocation, and it ends after the search date, but was cancelled before" do
        scholarship = FactoryGirl.create(:scholarship, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2015/01/31"))
        FactoryGirl.create(:scholarship_duration, :scholarship_id => scholarship.id, :start_date => Date.parse("2012/01/01"), :end_date => Date.parse("2013/03/31"), :cancel_date => Date.parse("2013/01/31"))
        condition = ScholarshipsController.condition_for_available_column(:available, {:use => 'yes', :month => "2", :year => "2013"}, "")
        Scholarship.where(condition.map(&:to_sql).join(' OR ')).should include(scholarship)
      end


    end

  end


end
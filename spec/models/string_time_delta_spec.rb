# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe StringTimeDelta do

  describe "multiply" do
    it ("should return 1 day if it is multiplying 1.day * 1") do
      StringTimeDelta::multiply(1.day, 1).should == 1.day
    end

    it ("should return 3 days if it is multiplying 1.day * 3") do
      StringTimeDelta::multiply(1.day, 3).should == 3.days
    end

    it ("should return -1 day if it is multiplying 1.day * -1") do
      StringTimeDelta::multiply(1.day, -1).should == -1.day
    end

    it ("should return -3 days if it is multiplying 1.day * -3") do
      StringTimeDelta::multiply(1.day, -3).should == -3.days
    end

    it ("should return 0 seconds if it is multiplying 1.day * 0") do
      StringTimeDelta::multiply(1.day, 0).should == 0.seconds
    end
  end

  describe "multiply" do
    it ("should return 1 second if it is parsing 1s") do
      StringTimeDelta::parse("1s").should == 1.second
    end

    it ("should return 1 minute if it is parsing 1m") do
      StringTimeDelta::parse("1m").should == 1.minute
    end

    it ("should return 2 hours if it is parsing 2h") do
      StringTimeDelta::parse("2h").should == 2.hours
    end

    it ("should return 3 days if it is parsing 3d") do
      StringTimeDelta::parse("3d").should == 3.days
    end

    it ("should return -1 week if it is parsing -1w") do
      StringTimeDelta::parse("-1w").should == -1.week
    end

    it ("should return -3 months if it is parsing -3M") do
      StringTimeDelta::parse("-3M").should == -3.months
    end
  
    it ("should return 1 year and 6 months if it is parsing 1y6M") do
      StringTimeDelta::parse("1y6M").should == (1.year + 6.months)
    end
 
  end

end
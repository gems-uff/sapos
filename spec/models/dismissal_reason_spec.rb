# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe DismissalReason do
  let(:dismissal_reason) { DismissalReason.new }
  subject { dismissal_reason }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          dismissal_reason.name = "DismissalReason name"
          dismissal_reason.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          dismissal_reason.name = nil
          dismissal_reason.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "DismissalReason name"
          FactoryGirl.create(:dismissal_reason, :name => name)
          dismissal_reason.name = name
          dismissal_reason.should have_error(:taken).on :name
        end
      end
    end
     describe "thesis_judgement" do
      context "should be valid when" do
        it "thesis_judgement is in the list" do
          dismissal_reason.thesis_judgement = DismissalReason::THESIS_JUDGEMENT.first
          dismissal_reason.should have(0).errors_on :thesis_judgement
        end
      end
      context "should have error blank when" do
        it "entrance_exam_result is null" do
          dismissal_reason.thesis_judgement = nil
          dismissal_reason.should have_error(:blank).on :thesis_judgement
        end
      end
      context "should have error inclusion when" do
        it "entrance_exam_result is not in the list" do
          dismissal_reason.thesis_judgement = "ANYTHING NOT IN THE LIST"
          dismissal_reason.should have_error(:inclusion).on :thesis_judgement
        end
      end
    end
  end
end
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

shared_examples_for "enrollment_user_helper" do
  let(:controller) { described_class } # Controller that includes concert
  before(:all) do
    @enrollment_status_with_user = FactoryBot.create(:enrollment_status, user: true)
    @enrollment_status_without_user = FactoryBot.create(:enrollment_status, user: false)
    @role = FactoryBot.create(:role)
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @enrollment_status_with_user.delete
    @enrollment_status_without_user.delete
    @role.delete
  end

  describe "append_first_selection" do
    it "should return a list with the first element that matches the condition" do
      input = [1, 2, 3, 4, 5, 6, 7]

      expect(controller.new.append_first_selection(input) { |n| n % 3 == 0 }).to eql({
        found: true,
        result: [3]
      })
    end

    it "should append to a previous list if it is passed as parameter" do
      previous = [2]

      input = [1, 2, 3, 4, 5, 6, 7]

      expect(controller.new.append_first_selection(input, previous) { |n| n % 3 == 0 }).to eql({
        found: true,
        result: [2, 3]
      })
    end

    it "should return an empty list when no conditions match the criteria" do
      input = [1, 2, 3, 4, 5, 6, 7]

      expect(controller.new.append_first_selection(input) { |n| n == 10 }).to eql({
        found: false,
        result: []
      })
    end
  end

  describe "enrollments_to_students_map" do
    it "should return a map with an entry for every student" do
      emails = ["abc@def.com", "def@ghi.com", "ghi@jkl.com"]
      delete_users_by_emails emails
      students = emails.map do |email|
        @destroy_later << student = FactoryBot.create(:student, email: email)
        student
      end
      enrollments = students.map { |student| FactoryBot.build(:enrollment, student: student, enrollment_status: @enrollment_status_with_user) }
      expect(controller.new.enrollments_to_students_map(enrollments)).to eql({
        students[0] => [enrollments[0]],
        students[1] => [enrollments[1]],
        students[2] => [enrollments[2]],
      })
    end

    it "should group enrollments by student" do
      emails = ["abc@def.com", "def@ghi.com", "ghi@jkl.com"]
      delete_users_by_emails emails
      students = emails.map do |email|
        @destroy_later << student = FactoryBot.create(:student, email: email)
        student
      end
      enrollments = students.map { |student| FactoryBot.build(:enrollment, student: student, enrollment_status: @enrollment_status_with_user) }
      enrollments << FactoryBot.build(:enrollment, student: students[1], enrollment_status: @enrollment_status_with_user)

      expect(controller.new.enrollments_to_students_map(enrollments)).to eql({
        students[0] => [enrollments[0]],
        students[1] => [enrollments[1], enrollments[3]],
        students[2] => [enrollments[2]],
      })
    end
  end

  describe "new_users_count" do
    let(:enrollments) do
      emails = ["abc@def.com", "def@ghi.com", "ghi@jkl.com", "jkl@mno.com", "mno@pqr.com"]
      delete_users_by_emails emails
      @destroy_later << FactoryBot.create(:user, email: "abc@def.com", role: @role)
      students = emails.map do |email|
        @destroy_later << student = FactoryBot.create(:student, email: email)
        student
      end
      students << student = FactoryBot.create(:student, email: nil)
      @destroy_later << student
      enrollments = students.map { |student| FactoryBot.build(:enrollment, student: student, enrollment_status: @enrollment_status_with_user) }
      enrollments << FactoryBot.build(:enrollment, student: students[1], enrollment_status: @enrollment_status_with_user)
      enrollments[2].enrollment_status = @enrollment_status_without_user
      enrollments[3].dismissal = FactoryBot.build(:dismissal)
      enrollments << FactoryBot.build(:enrollment, student: students[4], enrollment_status: @enrollment_status_with_user)
      enrollments[4].dismissal = FactoryBot.build(:dismissal)
      enrollments
    end
    it "should count the number of enrollments" do
      expect(controller.new.new_users_count(enrollments)[:enrollments]).to eql(8)
    end
    it "should count the number of allowed enrollments" do
      expect(controller.new.new_users_count(enrollments)[:allowedenrollments]).to eql(7)
    end
    it "should count the number of students" do
      expect(controller.new.new_users_count(enrollments)[:students]).to eql(5)
    end
    it "should count the number of students with users" do
      expect(controller.new.new_users_count(enrollments)[:existingstudents]).to eql(1)
    end
    it "should count the number of students without email" do
      expect(controller.new.new_users_count(enrollments)[:noemail]).to eql(1)
    end
    it "should count the number of users that should be added by default" do
      expect(controller.new.new_users_count(enrollments)[:default]).to eql(2)
    end
    it "should count the number of users that could be added when dismissed is selected" do
      expect(controller.new.new_users_count(enrollments)[:dismissed]).to eql(2)
    end
    it "should count the number of users that could be added when all are enabled" do
      expect(controller.new.new_users_count(enrollments)[:all]).to eql(3)
    end
  end

  describe "create_users" do
    let(:enrollments) do
      emails = ["abc@def.com", "def@ghi.com", "ghi@jkl.com", "jkl@mno.com", "mno@pqr.com"]
      delete_users_by_emails emails
      @destroy_later << FactoryBot.create(:user, email: "abc@def.com", role: @role)
      students = emails.map do |email|
        @destroy_later << student = FactoryBot.create(:student, email: email)
        student
      end
      students << student = FactoryBot.create(:student, email: nil)
      @destroy_later << student
      enrollments = students.map { |student| FactoryBot.build(:enrollment, student: student, enrollment_status: @enrollment_status_with_user) }
      enrollments << FactoryBot.build(:enrollment, student: students[1], enrollment_status: @enrollment_status_with_user)
      enrollments[2].enrollment_status = @enrollment_status_without_user
      enrollments[3].dismissal = FactoryBot.build(:dismissal)
      enrollments << FactoryBot.build(:enrollment, student: students[4], enrollment_status: @enrollment_status_with_user)
      enrollments[4].dismissal = FactoryBot.build(:dismissal)
      enrollments
    end
    it "should create two users through the default insertion" do
      expect(controller.new.create_enrollments_users(enrollments, "default")).to eql(2)
    end
    it "should create two users through the dismissed insertion" do
      expect(controller.new.create_enrollments_users(enrollments, "dismissed")).to eql(2)
    end
    it "should create three users through all insertion" do
      expect(controller.new.create_enrollments_users(enrollments, "all")).to eql(3)
    end
  end
end

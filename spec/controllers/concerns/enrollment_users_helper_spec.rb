# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'
require Rails.root.join "spec/support/user_helpers.rb"

RSpec.configure do |c|
  c.include UserHelpers
end

shared_examples_for "enrollment_user_helper" do
  let(:controller) { described_class } # Controller that includes concert
  let(:enrollment_status_with_user) { FactoryBot.create(:enrollment_status, :user => true) }
  let(:enrollment_status_without_user) { FactoryBot.create(:enrollment_status, :user => false) }

  describe "enrollments_that_should_have_user" do
    it "should return a list with the first enrollment that allows users when it exists" do
      user = User.find_by_email('abc@def.com')
      user.delete unless user.nil?
      
      student = FactoryBot.create(:student, :email => 'abc@def.com')
      enrollments = Array.new(3) { FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user) }
      enrollments[0].enrollment_status = enrollment_status_without_user

      expect(controller.new.enrollments_that_should_have_user(enrollments)).to eql({
        found: true,
        result: [enrollments[1]] 
      })
    end

    it "should append to a previous list if it is passed as parameter" do
      previous = FactoryBot.build(:enrollment)

      user = User.find_by_email('abc@def.com')
      user.delete unless user.nil?
      student = FactoryBot.create(:student, :email => 'abc@def.com')
      enrollments = Array.new(3) { FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user) }
      enrollments[0].enrollment_status = enrollment_status_without_user

      expect(controller.new.enrollments_that_should_have_user(enrollments, [previous])).to eql({
        found: true,
        result: [previous, enrollments[1]] 
      })
    end

    it "should return an empty list when no enrollments allow users" do
      user = User.find_by_email('abc@def.com')
      user.delete unless user.nil?
      student = FactoryBot.create(:student, :email => 'abc@def.com')
      enrollments = Array.new(3) { FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_without_user) }
      expect(controller.new.enrollments_that_should_have_user(enrollments)).to eql({
        found: false,
        result: [] 
      })
    end
  end

  describe "enrollments_to_students_map" do
    it "should return a map with an entry for every student" do
      emails = ['abc@def.com', 'def@ghi.com', 'ghi@jkl.com']
      delete_users_by_emails emails
      students = emails.map { |email| FactoryBot.create(:student, :email => email) }
      enrollments = students.map { |student| FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user) }
      expect(controller.new.enrollments_to_students_map(enrollments)).to eql({
        students[0] => [enrollments[0]],
        students[1] => [enrollments[1]],
        students[2] => [enrollments[2]],
      })
    end

    it "should group enrollments by student" do
      emails = ['abc@def.com', 'def@ghi.com', 'ghi@jkl.com']
      delete_users_by_emails emails
      students = emails.map { |email| FactoryBot.create(:student, :email => email) }
      enrollments = students.map { |student| FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user) }
      enrollments << FactoryBot.build(:enrollment, :student => students[1], :enrollment_status => enrollment_status_with_user)

      expect(controller.new.enrollments_to_students_map(enrollments)).to eql({
        students[0] => [enrollments[0]],
        students[1] => [enrollments[1], enrollments[3]],
        students[2] => [enrollments[2]],
      })
    end
  end

  describe "new_users_count" do
    let(:enrollments) do
      emails = ['abc@def.com', 'def@ghi.com', 'ghi@jkl.com']
      delete_users_by_emails emails
      FactoryBot.create(:user, :email => 'abc@def.com', :role => FactoryBot.create(:role))
      students = emails.map { |email| FactoryBot.create(:student, :email => email) }
      students << FactoryBot.create(:student, :email => nil)
      enrollments = students.map { |student| FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user) }
      enrollments << FactoryBot.build(:enrollment, :student => students[1], :enrollment_status => enrollment_status_with_user)
      enrollments[2].enrollment_status = enrollment_status_without_user
      enrollments
    end
    it "should count the number of enrollments" do
      expect(controller.new.new_users_count(enrollments)[:enrollments]).to eql(5)
    end
    it "should count the number of students" do
      expect(controller.new.new_users_count(enrollments)[:students]).to eql(4)
    end
    it "should count the number of students with users" do
      expect(controller.new.new_users_count(enrollments)[:existingstudents]).to eql(1)
    end
    it "should count the number of students without email" do
      expect(controller.new.new_users_count(enrollments)[:noemail]).to eql(1)
    end
    it "should count the number of users that should be added" do
      expect(controller.new.new_users_count(enrollments)[:default]).to eql(1)
    end
    it "should count the number of users that should be added without restrictions" do
      expect(controller.new.new_users_count(enrollments)[:force]).to eql(2)
    end
  end

  describe "create_users" do
    let(:enrollments) do
      emails = ['abc@def.com', 'def@ghi.com', 'ghi@jkl.com']
      delete_users_by_emails emails
      FactoryBot.create(:user, :email => 'abc@def.com', :role => FactoryBot.create(:role))
      students = emails.map { |email| FactoryBot.create(:student, :email => email) }
      students << FactoryBot.create(:student, :email => nil)
      enrollments = students.map { |student| FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user) }
      enrollments << FactoryBot.build(:enrollment, :student => students[1], :enrollment_status => enrollment_status_with_user)
      enrollments[2].enrollment_status = enrollment_status_without_user
      enrollments
    end
    it "should create one user when only one is available without forcing" do
      expect(controller.new.create_enrollments_users(enrollments, false)).to eql(1)
    end
    it "should create two users when two are available through forcing" do
      expect(controller.new.create_enrollments_users(enrollments, true)).to eql(2)
    end
  end

end

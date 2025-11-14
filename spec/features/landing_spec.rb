# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Landing features", type: :feature do
  let(:url_path) { "/landing" }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @role_student = FactoryBot.create(:role_aluno)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status1 = FactoryBot.create(:enrollment_status, name: "Regular")

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status1, admission_date: YearSemester.current.semester_begin - 3.years)
    @destroy_all << @enrollment5 = FactoryBot.create(:enrollment, enrollment_number: "D01", student: @student1, level: @level1, enrollment_status: @enrollment_status1, admission_date: YearSemester.current.semester_begin)

    @destroy_all << @student_user = create_confirmed_user([@role_student], "ana.sapos@ic.uff.br", "Ana", "A1b2c3d4!", student: @student1)

    @enrollment_status1.update!(user: true)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
    UserRole.delete_all
  end

  describe "view landing as admin" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should redirect to pendencies" do
      expect(page).to have_current_path("/pendencies")
    end
  end

  describe "view landing as student" do
    before(:each) do
      login_as(@student_user)
      visit url_path
    end

    it "should redirect to last enrollment page" do
      expect(page).to have_current_path("/enrollment/#{@enrollment5.id}")
    end
  end
end

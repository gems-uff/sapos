# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "maintenance:remove_expired_import_grade_previews", type: :task do
  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    Rake::Task["maintenance:remove_expired_import_grade_previews"].reenable
    @user = FactoryBot.create(:user)
    @turma = FactoryBot.create(:course_class)
  end

  def preview(token, created_at: Time.current)
    ImportGradePreview.create!(
      user: @user, course_class: @turma, token: token * 32,
      data: "{}", created_at: created_at
    )
  end

  it "remove so as previas vencidas" do
    velha = preview("a", created_at: 2.days.ago)
    nova = preview("b")

    Rake::Task["maintenance:remove_expired_import_grade_previews"].invoke

    expect(ImportGradePreview.exists?(velha.id)).to be false
    expect(ImportGradePreview.exists?(nova.id)).to be true
  end

  it "respeita o tempo limite configurado" do
    CustomVariable.create!(variable: "import_grades_session_timeout", value: "120")
    dentro = preview("c", created_at: 90.minutes.ago)
    fora = preview("d", created_at: 150.minutes.ago)

    Rake::Task["maintenance:remove_expired_import_grade_previews"].invoke

    expect(ImportGradePreview.exists?(dentro.id)).to be true
    expect(ImportGradePreview.exists?(fora.id)).to be false
  end
end

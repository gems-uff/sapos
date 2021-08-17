FactoryBot.define do
  factory :enrollment_request do
    year { 1 }
    semester { 1 }
    enrollment { nil }
    last_student_change_at { "2021-08-16 23:19:51" }
    last_professor_change_at { "2021-08-16 23:19:51" }
    last_coord_change_at { "2021-08-16 23:19:51" }
  end
end

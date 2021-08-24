FactoryBot.define do
  factory :enrollment_request_comment do
    message { "MyText" }
    enrollment_request { "" }
    user { "" }
    student_view_at { "2021-08-23 23:12:13" }
  end
end

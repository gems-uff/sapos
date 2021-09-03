FactoryBot.define do
  factory :enrollment_request_comment do
    message { "MyText" }
    enrollment_request { "" }
    user { "" }
  end
end

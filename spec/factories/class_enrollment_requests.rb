FactoryBot.define do
  factory :class_enrollment_request do
    enrollment_request { nil }
    course_class { nil }
    status_professor { false }
    status_coord { false }
  end
end

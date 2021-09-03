FactoryBot.define do
  factory :class_enrollment_request do
    enrollment_request { nil }
    course_class { nil }
    class_enrollment { nil }
    status { ClassEnrollmentRequest::REQUESTED }
  end
end

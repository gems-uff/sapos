FactoryBot.define do
  factory :email_template do
    name { "" }
    to { "MyString" }
    subject { "MyString" }
    body { "MyText" }
    enabled { false }
  end
end

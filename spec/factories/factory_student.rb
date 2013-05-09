# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :student do
    sequence :cpf do |cpf|
      "#{cpf}"
    end
    sequence :name do |name|
      "Student_#{name}"
    end
  end
end

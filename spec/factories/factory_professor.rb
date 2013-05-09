# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :professor do
    sequence :cpf do |cpf|
      "#{cpf}"
    end
    sequence :name do |name|
      "Professor_#{name}"
    end
  end
end

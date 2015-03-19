# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dismissal_reason do
  	thesis_judgement I18n.translate("activerecord.attributes.dismissal_reason.thesis_judgements.approved")
    sequence :name do |name|
      "DismissalReason_#{name}"
    end
  end
end

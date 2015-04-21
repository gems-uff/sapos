# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

FactoryGirl.define do
  factory :report_configuration do
    name "MyString"
    use_at_report false
    use_at_transcript false
    use_at_grades_report false
    use_at_schedule false
    text "MyText"
    image "MyString"
    signature_footer false
  end
end

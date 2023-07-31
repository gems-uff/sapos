# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

RSpec::Matchers.define :be_able_to_be_destroyed do
  match do |actual|
    delete_success = true
    obj = FactoryBot.create(actual.class.name.underscore.to_sym)
    begin
      obj.destroy
      delete_success = obj.destroyed?
    rescue ActiveRecord::DeleteRestrictionError
      delete_success = false
    end
    delete_success
  end

  failure_message do |actual|
    "It should be possible to delete a #{actual.class.name} record"
  end

  failure_message_when_negated do |actual|
    "It should not be possible to delete a #{actual.class.name} record"
  end
end

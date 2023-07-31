# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_have_error, :have_error

class AcceptMonthYearAssignmentOfMatcher
  include RSpec::Matchers

  def initialize(attribute, presence, year, month)
    @attribute = attribute
    @year = year
    @presence = presence
    @month = month
  end

  def matches?(subject)
    @matcher = not_have_error(:invalid_date).on @attribute
    if !@presence
      @message = "#{@attribute} to accept an empty month year date with day filled as '1'"
      subject.send(:assign_multiparameter_attributes, [["#{@attribute}(3i)", "1"], ["#{@attribute}(2i)", ""], ["#{@attribute}(1i)", ""]])
      return false unless @matcher.matches? subject
    end
    @message = "#{@attribute} to accept a month year date without a day field"
    subject.send(:assign_multiparameter_attributes, [["#{@attribute}(2i)", @month.to_s], ["#{@attribute}(1i)", @year.to_s]])
    return false unless @matcher.matches? subject
    @matcher = eq(Date.new(@year, @month, 1))
    @matcher.matches? subject.send(@attribute)
  end

  def failure_message
    "Expected #{@message}, but it did not accept the date: #{@matcher.failure_message}"
  end

  def failure_message_when_negated
    "Did not expect #{@message}, but it accepted it anyway: #{@matcher.failure_message}"
  end

  def description
    "accept a month-year date as multiparameter assignment of #{@attribute}"
  end
end

def accept_a_month_year_assignment_of(attribute, presence = false, year = Date.today.year, month = Date.today.month)
  AcceptMonthYearAssignmentOfMatcher.new(attribute, presence, year, month)
end

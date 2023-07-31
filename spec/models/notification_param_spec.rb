# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe NotificationParam, type: :model do
  before(:all) do
    @query = FactoryBot.create(:query)
  end
  after(:all) do
    @query.delete
  end
  let(:notification) { FactoryBot.build(:notification, query: @query) }
  let(:query_param) { FactoryBot.build(:query_param, query: @query) }


  let(:notification_param) do
    NotificationParam.new(
      notification: notification,
      query_param: query_param
    )
  end
  subject { notification_param }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:notification).required(true) }
    it { should belong_to(:query_param).required(true) }
  end
end

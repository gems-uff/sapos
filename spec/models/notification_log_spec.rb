# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe NotificationLog, type: :model do
  let(:notification_log) { NotificationLog.new }
  subject { notification_log }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:notification).required(false) }
  end
end

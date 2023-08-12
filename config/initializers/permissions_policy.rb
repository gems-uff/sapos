# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Define an application-wide HTTP permissions policy. For further
# information see https://developers.google.com/web/updates/2018/06/feature-policy
#
Rails.application.config.permissions_policy do |f|
  f.camera :self
  # f.gyroscope   :none
  # f.microphone  :none
  # f.usb         :none
  # f.fullscreen  :self
  # f.payment     :self, "https://secure.example.com"
end

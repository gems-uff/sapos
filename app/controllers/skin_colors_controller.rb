# frozen_string_literal: true

class SkinColorsController < ApplicationController
  active_scaffold :skin_color do |config|
    config.columns = [:name, :description]
  end
end

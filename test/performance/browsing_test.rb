# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'
require 'rails/performance_test_help'

# Profiling results for each test method are written to tmp/performance.
class BrowsingTest < ActionDispatch::PerformanceTest
  def test_homepage
    get '/'
  end
end

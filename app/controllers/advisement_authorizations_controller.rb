# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AdvisementAuthorizationsController < ApplicationController
  authorize_resource

  active_scaffold :advisement_authorization do |config|
    config.columns = [:professor, :level]
    config.actions.swap :search, :field_search
    config.field_search.columns = [:professor, :level]
    config.columns[:professor].search_ui = :record_select
    config.columns[:level].search_ui = :select
    config.columns[:professor].form_ui = :record_select
    config.columns[:level].form_ui = :select

  end
  record_select :per_page => 10
end
# encoding utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class VersionsController < ApplicationController
  authorize_resource

  active_scaffold :version do |config|
    config.columns = [:item_type, :item_id, :event, :whodunnit]

    config.columns[:item_type].label = I18n.t('activerecord.attributes.version.item_type')
    config.columns[:item_id].label = I18n.t('activerecord.attributes.version.item_id')
    config.columns[:event].label = I18n.t('activerecord.attributes.version.event')
    config.columns[:whodunnit].label = I18n.t('activerecord.attributes.version.whodunnit')

    config.actions.exclude :create, :delete, :update
  end
  record_select :per_page => 1, :order_by => 'created_at', :search_on => [:item_id]

 end

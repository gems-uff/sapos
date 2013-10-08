# encoding utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class VersionsController < ApplicationController
  authorize_resource

  active_scaffold :version do |config|
    config.columns = [:item_type, :current_object, :event, :user]
    config.list.sorting = {:created_at => 'DESC'}
    config.search.columns = [:user, :event, :item_type, :item_id]

    config.columns[:item_type].label = I18n.t('activerecord.attributes.version.item_type')
    config.columns[:current_object].label = I18n.t('activerecord.attributes.version.current_object')
    config.columns[:event].label = I18n.t('activerecord.attributes.version.event')
    config.columns[:user].label = I18n.t('activerecord.attributes.version.user')

    config.show.columns = [:item_type, :current_object, :event, :user, :old_version]

    config.actions.exclude :create, :delete, :update
  end

 end

# encoding utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module VersionsHelper
	def item_type_column(record, column)
		I18n.t("activerecord.models.#{record.item_type.downcase}.one")
	end

	def current_object_column(record, column)
		object_id = record.item_id.to_i
		model_str = record.item_type
		model = model_str.constantize

		if model.find_by_id(object_id).nil?
			I18n.t("activerecord.attributes.version.current_object_destroyed")
		else
			path = send((model_str.downcase + "_path").to_sym, object_id)
			route = Rails.application.routes.recognize_path(path)

			link_to(h(model.find(object_id).to_label), route) if object_id != 0
		end
	end

	def event_column(record, column)
		I18n.t("activerecord.attributes.version.event_options.#{record.event}")
	end

	def user_column(record, column)
		user_id = record.whodunnit.to_i
		link_to(h(User.find(user_id).name), user_path(User.find(user_id))) if user_id != 0
	end
end
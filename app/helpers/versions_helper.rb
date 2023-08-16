# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module VersionsHelper
  def item_type_column(record, column)
    I18n.t("activerecord.models.#{record.item_type.underscore}.one")
  end

  def current_object_column(record, column)
    object_id = record.item_id.to_i
    model_str = record.item_type
    model = model_str.constantize
    if model.find_by_id(object_id).nil?
      I18n.t("activerecord.attributes.version.current_object_destroyed")
    else
      begin
        path = send((model_str.underscore + "_path").to_sym, object_id)
        link_to(h(model.find(object_id).to_label), path) if object_id != 0
      rescue NoMethodError
        I18n.t("activerecord.attributes.version.relationship_object") if
          object_id != 0
      end
    end
  end

  def event_column(record, column)
    I18n.t("activerecord.attributes.version.event_options.#{record.event}")
  end

  def user_column(record, column)
    user_id = record.whodunnit.to_i
    link_to(h(User.find(user_id).name), user_path(User.find(user_id))) if
      user_id != 0
  end

  def created_at_column(record, column)
    record.created_at.strftime("%d/%m/%Y às %H:%M")
  end

  def old_version_show_column(record, column)
    if record.object.present?
      property_list = ""
      raw_property_list = record.object.split("\n")

      for property in raw_property_list
        if !property.end_with?(": ") &&
          !property.include?("password") &&
          !property.include?("_at") &&
          !property.include?("sign_in")
          # a string do objeto inicia com um ---
          property_list += (property + "<br>") if property != "---"
        end
      end
      html_escape(property_list).gsub("&lt;br&gt;", "<br>").html_safe
    end
  end
end

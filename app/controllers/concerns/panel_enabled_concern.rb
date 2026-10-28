# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Blocks access to Panel (Beta) controllers when the "enable_panel"
# custom variable is not turned on, redirecting the user back to the
# configurations area. This enforces the flag on the server side, so a
# stale menu link (changed without reloading the page) or a direct URL
# cannot reach a disabled Panel page.
module PanelEnabledConcern
  extend ActiveSupport::Concern

  included do
    before_action :ensure_panel_enabled
  end

  private
    def ensure_panel_enabled
      return if CustomVariable.enable_panel

      redirect_to custom_variables_path, alert: I18n.t("panel.disabled")
    end
end

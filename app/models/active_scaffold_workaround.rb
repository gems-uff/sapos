# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# This model (and table) exists because I needed a safe way to load
# active scaffold controllers for admission forms without exposing other models
# to external users.
# Exposing this table is safe because it doesn't have any data and there are
# no routes that use it
#
# The alternative for this workaround could be a complicated monkeypatch
# on the ActiveScaffold CanCan Bridge to prevent it from calling authorize_resource
# on controllers that only initialize active scaffold to have the form helpers
class ActiveScaffoldWorkaround < ApplicationRecord
end

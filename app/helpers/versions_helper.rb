# encoding utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module VersionsHelper
	def whodunnit_column(record, column)
		user_id = record.whodunnit.to_i
		link_to(h(User.find(user_id).name), user_path(User.find(user_id))) if user_id != 0
	end
end
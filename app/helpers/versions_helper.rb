# encoding utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module VersionsHelper
	def whodunnit_column(record, column)
		name = record.object[/:\s\w+/][2..-1] if not record.object.nil?
		name#link_to(h(name), :action => :show, :controller => 'users', :id => record.whodunnit)
	end
end
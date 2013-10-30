# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module StudentsHelper
	def enrollments_column(record, column)
		return record.enrollments_number
	end
end
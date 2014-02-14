# encoding utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module NotificationLogsHelper
	def notification_name_column(record, column)
		notification = record.notification
		unless notification.nil?
			link_to(h(notification.title), notification_path(notification))
		else
			I18n.t('activerecord.attributes.notification_log.notification_removed')
		end
	end

	def to_column(record, column)
		record.to.gsub(/[;,]/,'; ')
	end

	def created_at_column(record, column)
		I18n.l(record.created_at.in_time_zone)
	end
end
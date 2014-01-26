# coding: utf-8

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require './lib/notifier'

notifier = Notifier.instance

notifier.new_notification do
	notifications_to_execute = []
	notifications = []

	Notification.all.each do |notification|
	  notifications_to_execute << notification if notification.should_run?
	end

	#Create connection to the Database
	db_connection = ActiveRecord::Base.connection

	notifications_to_execute.each do |notification|
		#Generate query using the parameters specified by the notification
		params = {
			#Temos que definir todos os possíveis parametros que as buscas podem querer usar
		}
		query = (notification.sql_query % params).gsub("\r\n", " ")

		#Query the Database
		query_result = db_connection.select_all(query)

		#Build the notifications with the results from the query
		query_result.each do |raw_result|
			result = {}
			raw_result.each do |key , value|
				result[key.to_sym] = value
			end

	    notifications << {
				:to => notification.to_template % result,
				:subject => notification.subject_template % result,
				:body => notification.body_template % result
			}
	  end
	  notification.save
	end
	notifications
end

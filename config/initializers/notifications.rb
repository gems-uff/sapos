# coding: utf-8

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require './lib/notifier'

notifier = Notifier.instance


notifier.new_notification do
	notifications_to_execute = []
	Notification.all.each do |notification|
	  notifications_to_execute << notification if notification.should_execute?
	end

	notifications = []
	notifications_to_execute.each do |notification|
		#Create connection to the Database
		db_connection = ActiveRecord::Base.connection

		#Generate query using the parameters specified by the notification
		params = {
			:frequency => conn.quote(notification.frequency), 
			:query_offset => conn.quote(notification.query_offset), 
			:notification_offset => conn.quote(notification.notification_offset)
		}
		query = notification.sql_query % params

		#Query the Database
		query_result = db_connection.select_all(query)

		#Build the notifications with the results from the query
		query_result.each do |raw_result|
			result = {}
			raw_result.each do |key , value|
				result[key.to_symbol] = value
			end

	    notifications << {
				:to => notification.to_template % result,
				:subject => notification.subject_template % result,
				:body => notification.body_template % result
			}
	  end
	  notification.last_executed = Time.now
	  notification.save
	end
	notifications
end










#Notifies every student that hasn't completed one of the necessary phases that has only 30 days left until the due date
notifier.new_notification do
  notifications = []
  Phase.all.each do |phase|
    phase_completions = PhaseCompletion.where(
      "phase_id = ? AND due_date < ? AND completion_date IS NULL", 
      phase.id, 
      365.days.since(Date.today)
    )

    phase_completions.each do |phase_completion|
      notification = {
        :to => phase_completion.enrollment.student.email, 
        :subject => "O prazo da etapa #{phase.name} acaba em 30 dias", 
        :body => "Você tem 30 dias para realizar a etapa #{phase.name} ou pedir uma prorrogação" 
      }
      notifications << notification
    end
  end
  notifications
end

class Namespace
  def initialize(hash)
    hash.each do |key, value|
      singleton_class.send(:define_method, key) { value }
    end 
  end

  def get_binding
    binding
  end
end


notifier.new_notification do
  conn = ActiveRecord::Base.connection
  #Step 1: pre-conditions - conditions for today ("Última quarta-feira do mês"/Last Wednesday of each month)

  #Step 2: quote SQL params and convert dates ("7 dias antes"/7 days before)
  #date = 7.days.since Date.today
  #params = [date, date + 1.day]
  params = [Date.parse('2013-07-31'), Date.parse('2013-08-01')]
  params = params.map { |p| conn.quote(p)}
  result = conn.select_all "
    SELECT (SELECT email FROM users) as emails, students.email AS email, phases.name AS phase_name
    FROM phase_completions 
    INNER JOIN enrollments ON enrollments.id == phase_completions.enrollment_id 
    INNER JOIN students ON students.id == enrollments.student_id
    INNER JOIN phases ON phases.id == phase_completions.phase_id 
    WHERE due_date>=%s 
      AND due_date<%s 
      AND completion_date IS NULL" % params

  #Step 3: define template
  template = {
    :to => "<%= result['emails'].join(';') %>",
    :subject => "O prazo da etapa <%= result['phase_name'] %> acaba em 7 dias",
    :body => "Você tem 7 dias para realizar a etapa <%= result['phase_name'] %> ou pedir uma prorrogação"  
  }

  #Step 4: use each result in template to create notifications
  notifications = []
  result.each do |result|
    ns = Namespace.new(result: result, params: params)
    notification = {
      :to => ERB.new(template[:to], 3).result(ns.get_binding),
      :subject => ERB.new(template[:subject], 3).result(ns.get_binding),
      :body => ERB.new(template[:body], 3).result(ns.get_binding)
    }
    notifications << notification
  end
  notifications
end
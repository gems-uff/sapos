# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require './lib/notifier'

notifier = Notifier.instance

notifier.new_notification do
  phase_completions = PhaseCompletion.where("due_date < ? AND phase_id = ?", 30.days.since(Date.today), 1)
  notifications = []

  phase_completions.each do |phase_completion|
    unless phase_completion.enrollment.student.email.nil?
	    notification = {
	    	:to => phase_completion.enrollment.student.email, 
	    	:subject => "Test", 
	    	:body => "Test"
	    }
	  end
    notifications << notification
  end
  notifications
end
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require './lib/notifier'

notifier = Notifier.instance

notifier.new_notification do
  {:to => "sapos@mailinator.com", :body => "bla", :subject => "Primeira Mensagem"}
end

notifier.new_notification do
  [{:to => "sapos@mailinator.com", :body => "1", :subject => "Segunda Mensagem"},
    {:to => "joaofelipenp@gmail.com", :body => "2", :subject => "Terceira Mensagem"}]
end

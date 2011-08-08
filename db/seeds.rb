# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
User.create(:name => 'admin', :password => 'admin')
Sponsor.create(:name => "CAPES")
Sponsor.create(:name => "CNPq")
Sponsor.create(:name => "FAPERJ")
Sponsor.create(:name => "PETROBRAS")
Level.create(:name => "Regular")
Level.create(:name => "Especial")
Dismissal_reason.create(:name => "Defesa", :description => "Aluno defendeu")
Dismissal_reason.create(:name => "Desempenho", :description => "Aluno não cumpriu critérios de desempenho")
Dismissal_reason.create(:name => "Desistência", :description => "Aluno desistiu")
Dismissal_reason.create(:name => "Prazo", :description => "Prazo para defesa esgotado")
Dismissal_reason.create(:name => "Regular", :description => "Aluno foi admitido como aluno regular")


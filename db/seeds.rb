# encoding: utf-8
# 
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

Level.create(:name => "Graduação")
Level.create(:name => "Especialização")
Level.create(:name => "Mestrado")
Level.create(:name => "Doutorado")

EnrollmentStatus.create(:name => "Especial")
EnrollmentStatus.create(:name => "Regular")

DismissalReason.create(:name => "Defesa", :description => "Aluno defendeu")
DismissalReason.create(:name => "Rendimento", :description => "Aluno não cumpriu critérios de rendimento")
DismissalReason.create(:name => "Desistência", :description => "Aluno desistiu")
DismissalReason.create(:name => "Prazo", :description => "Prazo para defesa esgotado")
DismissalReason.create(:name => "Especial -> Regular", :description => "Aluno foi admitido como aluno regular")

Role.create(:name => "Administrador", :description => "Administrador")
Role.create(:name => "Coordenação", :description => "Coordenação")
Role.create(:name => "Secretaria", :description => "Secretaria")
Role.create(:name => "Professor", :description => "Professor")
Role.create(:name => "Aluno", :description => "Aluno")

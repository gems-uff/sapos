# encoding: utf-8

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# 
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago', :description =>'Chicago' }, { :name => 'Copenhagen', :description =>'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :description =>'Daley', :city => cities.first)
User.create(:name => 'admin', :description => 'admin', :password => 'admin')

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

[
    {:id => 1, :name => 'Desconhecido', :description => 'Desconhecido'},
    {:id => 2, :name => 'Coordenação', :description => 'Coordenação'},
    {:id => 3, :name => 'Secretaria', :description => 'Secretaria'},
    {:id => 4, :name => 'Professor', :description => 'Professor'},
    {:id => 5, :name => 'Aluno', :description => 'Aluno'},
    {:id => 6, :name => 'Administrador', :description => 'Administrador'}
].each do |role|
  current_role = Role.find_by_id(role[:id])
  if current_role
    current_role.name = role[:name]
    current_role.description = role[:description]
    current_role.save!
  else
    Role.new do |r|
      r.id = role[:id]
      r.name = role[:name]
      r.description = role[:description]
    end.save!
  end
end

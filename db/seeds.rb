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
user = User.new do |u| 
  u.name = 'admin'
  u.email = 'admin@admin.com'
  u.password = 'admin'
end
user.save
user.confirm!

['CAPES', 'CNPq', 'FAPERJ', 'PETROBRAS'].each do |sponsor|
  Sponsor.new do |s|
    s.name = sponsor
  end.save
end

['Graduação', 'Especialização', 'Mestrado', 'Doutorado'].each do |level|
    Level.new do |l|
      l.name = level
    end.save
end

['Especial', 'Regular'].each do |enrollment|
      EnrollmentStatus.new do |e|
        e.name = enrollment
      end.save
end

DismissalReason.new do |d| 
  d.name = "Defesa"
  d.description = "Aluno defendeu"
end
DismissalReason.new do |d|
  d.name = "Rendimento"
  d.description = "Aluno não cumpriu critérios de rendimento"
end
DismissalReason.new do |d|
  d.name = "Desistência"
  d.description = "Aluno desistiu"
end
DismissalReason.new do |d|
  d.name = "Prazo"
  d.description = "Prazo para defesa esgotado"
end
DismissalReason.new do |d|
  d.name = "Especial -> Regular"
  d.description = "Aluno foi admitido como aluno regular"
end

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

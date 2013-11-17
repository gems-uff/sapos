# coding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class UpdateRoles < ActiveRecord::Migration
  def self.up
    Role.transaction do
      User.where(:role_id => 6).update_all(:role_id => 4)
      User.where(:role_id => 7).update_all(:role_id => 5)
      User.where(:role_id => 8).update_all(:role_id => 6)
      role7 = Role.find_by_id(7)
      role7.destroy unless role7.nil?
      role8 = Role.find_by_id(8)
      role8.destroy unless role8.nil?
      [
          {:id => 1, :name => 'Desconhecido', :description => 'Desconhecido'},
          {:id => 2, :name => 'Coordenação', :description => 'Coordenação'},
          {:id => 3, :name => 'Secretaria', :description => 'Secretaria'},
          {:id => 4, :name => 'Professor', :description => 'Professor'},
          {:id => 5, :name => 'Aluno', :description => 'Aluno'},
          {:id => 6, :name => 'Administrador', :description => 'Administrador'}
      ].each do |role|
        current_role = Role.find_by_id(role[:id])
        unless current_role.nil?
          current_role.name = role[:name]
          current_role.description = role[:description]
          current_role.save!
        end
      end
    end
  end

  def self.down
    Role.transaction do
      [
          {:id => 1, :name => 'Desconhecido', :description => 'Desconhecido'},
          {:id => 2, :name => 'Coordenação', :description => 'Coordenação'},
          {:id => 3, :name => 'Secretaria de bolsas', :description => 'Secretaria de bolsas'},
          {:id => 4, :name => 'Secretaria de matrículas', :description => 'Secretaria de matrículas'},
          {:id => 5, :name => 'Secretaria de Manutenção de Matrícula', :description => 'Secretaria de Manutenção de Matrícula'},
          {:id => 6, :name => 'Professor', :description => 'Professor'},
          {:id => 7, :name => 'Aluno', :description => 'Aluno'},
          {:id => 8, :name => 'Administrador', :description => 'Administrador'}
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

      User.where(:role_id => 6).update_all(:role_id => 8)
      User.where(:role_id => 5).update_all(:role_id => 7)
      User.where(:role_id => 4).update_all(:role_id => 6)
    end
  end
end

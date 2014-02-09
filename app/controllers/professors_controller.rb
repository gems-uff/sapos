# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ProfessorsController < ApplicationController
  authorize_resource

  include NumbersHelper
  include ApplicationHelper
  helper :class_enrollments
  helper :professor_research_areas

  active_scaffold :professor do |config|
    config.columns.add :advisement_points
    config.columns.add :advisements_with_points
    config.list.columns = [:name, :cpf, :birthdate, :advisement_points, :enrollment_number]
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_professor_label
    config.columns[:advisement_points].sort_by :method => "advisement_points_order"
    config.columns[:enrollments].associated_limit = nil
    config.columns[:birthdate].options = {'date:yearRange' => 'c-100:c'}
    config.columns[:civil_status].form_ui = :select
    config.columns[:civil_status].options = {:options => [['Solteiro(a)', 'solteiro'],
                                                          ['Casado(a)', 'casado']]}
    config.columns[:institution].form_ui = :record_select
    config.columns[:sex].form_ui = :select
    config.columns[:sex].options = {:options => [['Masculino', 'M'],
                                                 ['Feminino', 'F']]}
    config.columns[:scholarships].form_ui = :record_select
    config.columns[:professor_research_areas].includes = {:research_areas => :professor_research_areas}
    form_columns = [:name,
                    :email,
                   :sex,
                   :civil_status,
                   :birthdate,
                   :city,
                   :neighborhood,
                   :address,
                   :zip_code,
                   :telephone1,
                   :telephone2,
                   :cpf,   
                   :identity_expedition_date,
                   :identity_issuing_body,
                   :identity_issuing_place,
                   :identity_number,
                   :enrollment_number,
                   :siape,
                   :institution,
                   :scholarships,
                   :professor_research_areas]

    config.create.columns = form_columns
    config.update.columns = form_columns


    config.show.columns = [:name,
                           :email,
                           :cpf,
                           :birthdate,
                           :address,
                           :birthdate,
                           :civil_status,
                           :identity_expedition_date,
                           :identity_issuing_body,
                           :identity_number,
                           :neighborhood,
                           :sex,
                           :enrollment_number,
                           :siape,
                           :telephone1,
                           :telephone2,
                           :zip_code,
                           :scholarships,
                           :advisement_authorizations,
                           :advisements_with_points,
                           :research_areas]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

end
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Course < ApplicationRecord
  belongs_to :research_area
  # attr_accessible :name, :code, :content, :credits, :workload, :available

  has_many :course_research_areas, :dependent => :destroy
  has_many :research_areas, :through => :course_research_areas
  
  belongs_to :course_type
  has_many :course_classes, :dependent => :restrict_with_exception

  has_paper_trail

  validates :course_type, :presence => true
  validates :name, :presence => true
  validate  :check_unique_name_for_available_courses
  validates :code, :presence => true, :uniqueness => true
  validates :credits, :presence => true
  validates :workload, :presence => true

  def to_label
       "#{self.name}"
  end

  def workload_value
    workload.nil? ? 0 : workload
  end

  def workload_text
    return I18n.translate('activerecord.attributes.course.empty_workload') if workload.nil?
    I18n.translate('activerecord.attributes.course.workload_time', :time => workload)
  end

  def self.ids_de_disciplinas_com_nome_parecido(id_disciplina_selecionada)
    ids = []
    disciplina_selecionada = Course.find_by(id: id_disciplina_selecionada) 
    unless disciplina_selecionada.nil?
      nome_disciplina_selecionada = I18n.transliterate(disciplina_selecionada.name.squish.downcase)
      disciplinas = Course.all.collect{|c| [c.name, c.id]}
      disciplinas.each do |disciplina|
        if nome_disciplina_selecionada == I18n.transliterate(disciplina[0].squish.downcase)  
          ids.push(disciplina[1])
        end
      end
    end
    return ids
  end

  private

  def check_unique_name_for_available_courses
    if available && (not name.nil?)
      nome_da_disciplina = I18n.transliterate(name.squish.downcase)
      nomes_das_outras_disciplinas = Course.where(:available => true).where.not(:id => id).collect{|c| [c.name]}
      nomes_das_outras_disciplinas.each do |nome_da_outra_disciplina|
        if nome_da_disciplina == I18n.transliterate(nome_da_outra_disciplina[0].squish.downcase)
          errors.add(:name, "#{I18n.t('activerecord.errors.models.course.check_unique_name_for_available_courses')}")
	end
      end
    end
  end

end

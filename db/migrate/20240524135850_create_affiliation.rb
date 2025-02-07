class CreateAffiliation < ActiveRecord::Migration[7.0]
  def up
    create_table :affiliations do |t|
      t.belongs_to :professor, index: true
      t.belongs_to :institution, index: true
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
    Professor.where.not(institution_id: nil).each do |professor|
      initial_start_date = Enrollment.joins(:thesis_defense_committee_participations).
        where(thesis_defense_committee_participations: { professor: professor }).minimum(:thesis_defense_date)

      start_date = professor.updated_at
      end_date = nil
      institution_id = professor.institution_id
      institutions = []
      affiliation = Affiliation.create(
        professor: professor,
        institution_id: institution_id,
        start_date: start_date
      )
      professor = professor.paper_trail.previous_version
      while professor.present?
        # A data final é a data inicial da instituição anterior
        end_date = start_date
        # A data inicial é quando o professor recebeu algum
        start_date = professor.updated_at
        if ((professor.institution_id != institution_id )&& ((end_date - start_date) > 1.month)) && (!professor.institution_id.nil?)
          # Atualiza a data caso a mudança de instituição seja maior que 1 mes, tenha uma intuição não nula diferente da atual
          institutions << { institution_id:, start_date:, end_date: }
          institution_id = professor.institution_id
          affiliation.update(start_date: start_date)
          affiliation = Affiliation.create(
            professor: professor,
            institution_id: institution_id,
            start_date: start_date - 1.month,
            end_date: end_date
          )
        end
        professor = professor.paper_trail.previous_version
      end
      if initial_start_date.nil? && initial_start_date >= start_date
        affiliation.update(start_date: start_date - 1.month)
      elsif initial_start_date >= start_date
        affiliation.update(start_date: initial_start_date - 1.month)
      end
      institutions << { institution_id:, start_date:, end_date: }
    end

    remove_column :professors, :institution_id
  end
  def down
    add_column :professors, :institution_id, :integer
    add_index :professors, :institution_id
    Professor.all.each do |p|
      affiliation = Affiliation&.of_professor(p)&.where(end_date: nil)&.last
      p.update(institution_id: affiliation&.institution_id)
    end
    drop_table :affiliations
  end
end

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
      first_committee_participation_date = Enrollment.joins(:thesis_defense_committee_participations).
        where(thesis_defense_committee_participations: { professor: professor }).minimum(:thesis_defense_date)

      start_date = professor.updated_at
      end_date = nil
      institution_id = professor.institution_id
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
        if (end_date - start_date) > 1.month
          if (professor.institution_id != institution_id) && (!professor.institution_id.nil?)
            # Atualiza a data caso a mudança de instituição seja maior que 1 mes, tenha uma intuição não nula diferente da atual
            institution_id = professor.institution_id
            affiliation.update(start_date: start_date)
            affiliation = Affiliation.create(
              professor: professor,
              institution_id: institution_id,
              start_date: start_date - 1.month,
              end_date: end_date
            )
          else
            affiliation.update(start_date: start_date)
          end
        end
        professor = professor.paper_trail.previous_version

      end
      if first_committee_participation_date.nil? || (first_committee_participation_date >= start_date)
        affiliation.update(start_date: start_date - 1.month)
      elsif first_committee_participation_date <= start_date
        affiliation.update(start_date: first_committee_participation_date - 1.month)
      end
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

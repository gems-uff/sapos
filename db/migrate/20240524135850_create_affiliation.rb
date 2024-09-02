class CreateAffiliation < ActiveRecord::Migration[7.0]
  def up
    create_table :affiliations do |t|
      t.belongs_to :professor, index: true
      t.belongs_to :institution, index: true
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
    Professor.all.each do |professor|
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
        if professor.institution_id != institution_id
          if institution_id.present? # Não armazena afiliação em branco
            institutions << { institution_id:, start_date:, end_date: }
          end
          end_date = start_date
          start_date = professor.updated_at
          institution_id = professor.institution_id
          affiliation = Affiliation.create(
            professor: professor,
            institution_id: institution_id,
            start_date: start_date,
            end_date: end_date
          )
        else
          # Atualiza data de início para data da primeira mudança em que instituição foi definida com esse valor
          start_date = professor.updated_at
          affiliation.update(start_date: start_date)
        end
        professor = professor.paper_trail.previous_version
      end
      if institution_id.present? # Não armazena afiliação em branco
        institutions << { institution_id:, start_date:, end_date: }
      end
    end

    remove_column :professors, :institution_id
  end
  def down
    add_column :professors, :institution_id, :integer
    add_index :professors, :institution_id
    Professor.all.each do |p|
      affiliation = Affiliation.of_professor(p).where(end_date: nil).last
      p.update(institution_id: affiliation.institution_id)
    end
    drop_table :affiliations
  end
end

class CreateProgramLevel < ActiveRecord::Migration[7.0]
  def up
    create_table :program_levels do |t|
      t.integer :level, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date

      t.timestamps
    end
    CustomVariable.where(variable: "program_level").each do |pl|
      first_committee_date = Enrollment.minimum(:thesis_defense_date)

      start_date = pl.updated_at
      end_date = nil
      level = pl.value      
      program_level = ProgramLevel.create(
        level: level,
        start_date: start_date,
      )
      
      pl = pl.paper_trail.previous_version      
      while pl.present?
        end_date = start_date
        start_date = pl.updated_at
        # When last version has another level, the level is not null, and the interval is greater than one month, register the last version
        if (pl.value != level) && (!pl.value.nil?) && ((end_date - start_date) > 1.month)
          level = pl.value
          program_level = ProgramLevel.create(
            level: level,
            start_date: start_date,
            end_date: end_date
          )
        else # Otherwise, only moves the start date
          program_level.update(start_date: start_date)
        end
        pl = pl.paper_trail.previous_version
      end
      if first_committee_date.nil? || (first_committee_date >= start_date)
        program_level.update(start_date: start_date - 1.month)
      elsif first_committee_date < start_date
        program_level.update(start_date: first_committee_date - 1.month)
      end
    end
    CustomVariable.where(variable: "program_level").destroy_all
  end
  def down
    ProgramLevel.all&.where(end_date: nil)&.each do |pl|
      CustomVariable.create(
        variable: "program_level",
        value: pl.level,
      )
    end
    drop_table :program_levels
  end
end

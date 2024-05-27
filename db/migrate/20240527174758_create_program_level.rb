class CreateProgramLevel < ActiveRecord::Migration[7.0]
  def up
    create_table :program_levels do |t|
      t.integer :level, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.boolean :active, null: false

      t.timestamps
    end
    CustomVariable.where(variable: "program_level").each do |pl|
      ProgramLevel.create(
        level: pl.value,
        start_date: pl.updated_at,
        active: true
      )
      date = pl.updated_at
      until pl.nil? do
        pl = pl.paper_trail.previous_version
        ProgramLevel.create(
          level: pl&.value,
          start_date: pl&.created_at,
          end_date: date,
          active: false
        )
      end
    end
    cvs = PaperTrail::Version.where(item_type: "CustomVariable")
    cvs.each do |c|
      next unless c&.object&.variable.eql?("program_level")

      program_level = c&.object
      if c&.event.eql?("create") && !program_level.in?(CustomVariable.all)
        ProgramLevel.create(
          level: program_level&.value,
          start_date: c.updated_at,
          active: true
        )

      elsif c.event.eql?("update") && !program_level&.previous_version.eql?(program_level)
        ProgramLevel.last.update(
          active: false,
          end_date: c.created_at
        )
        ProgramLevel.create(
          level: program_level&.value,
          start_date: c.created_at,
          active: true
        )
      elsif c.event.eql?("destroy")
        ProgramLevel.last.update(
          active: false,
          end_date: c.created_at
        )
      end

    end
  end
  def down
    ProgramLevel.each do |pl|
      CustomVariable.create(
        variable: "program_level",
        value: pl.level
      )
    end
    drop_table :program_levels
  end
end

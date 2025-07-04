class GenerateOrdinanceToProgramLevel < ActiveRecord::Migration[7.0]
  def up
    Level.find_each do |level|
      next if level.course_name.nil?
      match = level.course_name.match(/\(([^)]+)\)/)
      next unless match

      ordinance_text = match[1]
      year_match = ordinance_text.match(/(\d{4})$/)

      year = year_match[1].to_i

      ProgramLevel.find_each do |program|
        if program.start_date.year < year && (program.end_date.nil? || program.end_date.year > year)
          program.update!(ordinance: ordinance_text) if program.ordinance.nil?
        end
      end
      new_course_name = level.course_name.sub(/\s*\([^)]+\)/, "")
      level.update!(course_name: new_course_name)
    end
  end

  def down
    program = ProgramLevel.where.not(ordinance: nil).order(start_date: :desc).first
    return if program.nil?
    ordi = program.ordinance
    Level.find_each do |level|
      next if level.course_name.nil?
      new_course_name = "#{level.course_name} (#{ordi})"
      level.update!(course_name: new_course_name)
    end
    ProgramLevel.find_each do |program|
      program.update!(ordinance: nil)
    end
  end
end

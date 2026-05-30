class GenerateEndDateToScholarshipDurations < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        ScholarshipDuration.find_each do |scholarship_duration|
          if scholarship_duration.end_date.blank?
            puts "ID da alocação: #{scholarship_duration.id}"
            puts "Nome do aluno: #{scholarship_duration.enrollment.student.name}"
            puts "Número da bolsa: #{scholarship_duration.scholarship.scholarship_number}"
            puts "--------------------"
            scholarship_duration.update_end_date
            scholarship_duration.save!
          end
        end
      end
    end
  end
end

class AddImportGradesSessionTimeoutCustomVariable < ActiveRecord::Migration[8.1]
  def up
    CustomVariable.find_or_create_by(variable: "import_grades_session_timeout") do |cv|
      cv.description = "Tempo, em minutos, que a prévia de importação de notas fica válida na sessão"
      cv.value = "45"
    end
  end
end

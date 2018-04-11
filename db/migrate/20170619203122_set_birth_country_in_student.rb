class SetBirthCountryInStudent < ActiveRecord::Migration[5.1]
  def change

    students = Student.where(" (birth_country_id IS NULL) and ( (birth_state_id IS NOT NULL) or (birth_city_id IS NOT NULL) ) ")

    students.each do |student|
      if student.birth_state_id != nil
        student.birth_country_id = student.birth_state.country_id
      else
        student.birth_country_id = student.birth_city.state.country_id
      end 
      student.save  
    end

  end
end

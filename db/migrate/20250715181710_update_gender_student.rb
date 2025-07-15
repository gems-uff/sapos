class UpdateGenderStudent < ActiveRecord::Migration[7.0]
  def change
    actual_genders = I18n.t("active_scaffold.admissions/form_template.generate_fields.genders").keys
    Student.where.not(gender: actual_genders) do |student|
      student.update(gender: nil)
    end
  end
end

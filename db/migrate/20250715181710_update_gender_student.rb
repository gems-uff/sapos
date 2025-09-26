class UpdateGenderStudent < ActiveRecord::Migration[7.0]
  def change
    actual_genders = I18n.t("active_scaffold.admissions/form_template.generate_fields.genders").values

    Student.where.not(gender: actual_genders).each do |student|
      student.update(gender: nil)
      student.save
    end

    nd_sex = "ND"

    Student.where(sex: nd_sex).each do |student|
      student.update(sex: nil)
      student.save
    end
  end
end

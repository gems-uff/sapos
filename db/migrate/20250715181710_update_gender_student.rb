class UpdateGenderStudent < ActiveRecord::Migration[7.0]
  def change
    actual_genders = I18n.t("active_scaffold.admissions/form_template.generate_fields.genders").values - ['Não declarado']

    Student.where.not(gender: actual_genders).each do |student|
      student.update(gender: nil)
      student.save
    end

    nd_sex = "ND"

    Student.where(sex: nd_sex).each do |student|
      student.update(sex: nil)
      student.save
    end

    Student.where(humanitarian_policy: "Não declarado").each do |student|
      student.update(humanitarian_policy: nil)
      student.save
    end

    Student.where(pcd: "Não declarado").each do |student|
      student.update(pcd: nil)
      student.save
    end

    Student.where(skin_color: "Não declarado").each do |student|
      student.update(skin_color: nil)
      student.save
    end


  end
end

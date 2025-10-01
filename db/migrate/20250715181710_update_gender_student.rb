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

    actual_hp = I18n.t("active_scaffold.admissions/form_template.generate_fields.humanitarian_policies").values

    Student.where.not(humanitarian_policy: actual_hp).each do |student|
      student.update(humanitarian_policy: nil)
      student.save
    end

    actual_pcd = I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiencies").values

    Student.where.not(pcd: actual_pcd).each do |student|
      student.update(pcd: nil)
      student.save
    end

    actual_skin_color = I18n.t("active_scaffold.admissions/form_template.generate_fields.skin_colors").values
    Student.where.not(skin_color: actual_skin_color).each do |student|
      student.update(skin_color: nil)
      student.save
    end


  end
end

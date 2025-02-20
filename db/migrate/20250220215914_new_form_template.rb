class NewFormTemplate < ActiveRecord::Migration[7.0]
  def change
    Admissions::FormTemplate.all.each do |form_template|
      fields = form_template.fields

      field = fields.find_by(name: "Raça/cor")
      field.field_type = Admissions::FormField::STUDENT_FIELD
      values = I18n.t("active_scaffold.admissions/form_template.generate_fields.race_colors").values
      binding.pry
      field.configuration["values"] = values
      field.save

      field = fields.find_by(name: "Pessoa com deficiência")
      field.field_type = Admissions::FormField::STUDENT_FIELD
      values = I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiences").values
      field.configuration["values"] = values
      field.save

      field = fields.find_by(name: "Sexo")
      field.field_type = Admissions::FormField::STUDENT_FIELD
      values = ["Masculino", "Feminino", "Não declarado"]
      field.configuration["values"] = values
      field.save

      fields.where("order >= ?", 6).update_all("order = order + 1")
      field = Admission::FormField.new(
        name: I18n.t("active_scaffold.admissions/form_template.generate_fields.refugee"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        order: 6,
        configuration: JSON.dump({
                                   "field": "refugee",
                                   "values": I18n.t("active_scaffold.admissions/form_template.generate_fields.refugees").values,
                                   "required": true })
      )
      field.form_template = form_template
      field.save



      fields.where("order >= ?", 8).update_all("order = order + 1")
      field = Admission::FormField.new(
        name: I18n.t("active_scaffold.admissions/form_template.generate_fields.gender"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        order: 8,
        configuration: JSON.dump({ "field": "gender", "required": true }),
      )
      field.form_template = form_template
      field.save


    end
  end
end

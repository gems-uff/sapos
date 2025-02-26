class NewFormTemplate < ActiveRecord::Migration[7.0]
  def up
    Admissions::AdmissionProcess.all.each do |admission_process|
      form_template = admission_process.form_template
      fields = form_template&.fields

      field = fields&.find_by(name: "Raça/cor")
      field&.field_type = Admissions::FormField::STUDENT_FIELD
      values = I18n.t("active_scaffold.admissions/form_template.generate_fields.skin_colors").values
      if field&.configuration
        configuration = JSON.parse(field.configuration)
        configuration["values"] = values
        field.configuration = configuration.to_s
      end
      field&.save

      field = fields&.find_by(name: "Pessoa com deficiência")
      field&.field_type = Admissions::FormField::STUDENT_FIELD
      values = I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiencies").values
      if field&.configuration
        configuration = JSON.parse(field.configuration)
        configuration["values"] = values
        field.configuration = configuration.to_s
      end
      field&.save

      field = fields&.find_by(name: "Sexo")
      field&.field_type = Admissions::FormField::STUDENT_FIELD
      values = ["Masculino", "Feminino", "Não declarado"]
      if field&.configuration
        configuration = JSON.parse(field.configuration)
        configuration["values"] = values
        field.configuration = configuration.to_s
      end
      field&.save


    end
  end
  def down
    Admissions::AdmissionProcess.all.each do |admission_process|
      form_template = admission_process.form_template
      fields = form_template&.fields

      field = fields&.find_by(name: "Raça/cor")
      field&.field_type = Admissions::FormField::SELECT
      values = ["Sim", "Não"]
      if field&.configuration
        configuration = JSON.parse(field.configuration)
        configuration["values"] = values
        field.configuration = configuration.to_s
      end
      field&.save

      field = fields&.find_by(name: "Pessoa com deficiência")
      field&.field_type = Admissions::FormField::SELECT
      values = ["Sim", "Não"]
      if field&.configuration
        configuration = JSON.parse(field.configuration)
        configuration["values"] = values
        field.configuration = configuration.to_s
      end
      field&.save

      field = fields&.find_by(name: "Sexo")
      field&.field_type = Admissions::FormField::SELECT
      values = ["Masculino", "Feminino", "Não declarado"]
      if field&.configuration
        configuration = JSON.parse(field.configuration)
        configuration["values"] = values
        field.configuration = configuration.to_s
      end
      field&.save


    end
  end
end

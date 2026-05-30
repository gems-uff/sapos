class MigrateAdmissionsToStudent < ActiveRecord::Migration[7.0]
  def up
    Admissions::AdmissionApplication.where.not(student_id: nil).each do |admission|
      student = admission.student

      filled_form = admission.filled_form
      form_template = filled_form.form_template

      form_fields = form_template.fields
      form_fields = form_fields.where(name: "Raça/cor").or(form_fields.where(name: "Pessoa com deficiência"))
      form_fields_ids = form_fields.pluck(:id)

      filled_form.fields.where("form_field_id IN (:form_fields_ids)", form_fields_ids: form_fields_ids).each do |field|
        if field.form_field_id == form_fields.where(name: "Raça/cor").first&.id
          student.skin_color = field.value
        elsif field.form_field_id == form_fields.where(name: "Pessoa com deficiência").first&.id
          student.pcd = field.value
        end

      end
      student.save
    end
  end
  def down
    Admissions::AdmissionApplication.where.not(student_id: nil).each do |admission|
      student = admission.student

      student = student.paper_trail.previous_version
      student.save
    end
  end
end

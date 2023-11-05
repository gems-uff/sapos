function config_form_field_student(form_field, field) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let id = `${form_field.baseid}_${field}_special_notice_${r}`
  options = {
    onchange: function(selectid, selected_value) {
      let student_form_field = form_field.derive(`${selectid}-extra`);
      let show_notice = true;
      let field_type = "requirable";
      if (["special_city", "special_birth_city"].includes(selected_value)) {
        field_type = "city"
      } else if (selected_value == "special_address") {
        field_type = "residency"
      } else if (selected_value == "special_majors") {
        field_type = "scholarity"
      } else if (selected_value == "photo") {
        field_type = "file"
        show_notice = false;
      } else {
        show_notice = false;
      }
      $(`#${id}`).toggle(show_notice)
      student_form_field.select(field_type)
    },
    required: true
  }
  result = config_form_field_select(form_field, field, form_field.student_columns, options)
  result.html += `<p id="${id}" style="display:none;"> * ${form_field.i18n("special_field_notice")} </p>`
  return result
}

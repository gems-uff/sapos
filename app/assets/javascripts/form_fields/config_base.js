
function form_field_config_base(form_field) {
  form_field.baseid ||= "form_field_id";
  form_field.data ||= {};
  form_field.student_columns ||= [];
  form_field.translation ||= {};
  form_field.error_translation ||= {};

  function translate(current, keys, missing) {
    for (let key of keys) {
      if (current[key] == undefined) {
        return `${missing}: ${keys.join(".")}`
      }
      current = current[key]
    }
    return current
  }

  form_field.save ||= (data) => {};
  form_field.validate ||= (valid) => {};

  form_field.widgets = []

  form_field.i18n = (...keys) => translate(
    form_field.translation, keys, "Translation missing");
  form_field.i18n_error = (...keys) => translate(
    form_field.error_translation, keys, "Error translation missing");

  form_field.check_validity = () => {
    let valid = !form_field.widgets.every((widget) => widget.validate());
    form_field.validate(valid)
  }

  form_field.refresh = () => {
    form_field.widgets.forEach((widget) => widget.refresh());
  }

  form_field.save_config = () => {
    if (form_field.data) {
      form_field.save(form_field.data)
    }
    form_field.check_validity();
  }

  form_field.derive = (new_baseid) => {
    return form_field_config_base({ ...form_field,
      baseid: new_baseid
    })
  }

  form_field.select = (selected_value) => {
    form_field.widgets = [];
    if (selected_value == "requirable") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
      ]
    } else if (selected_value == "file" ) {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_values_sql(form_field, "values", { 
          label: "extensions"
        }),
      ]
    } else if (selected_value == "string") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_input(form_field, "default"),
        config_form_field_input(form_field, "placeholder")
      ]
    } else if (selected_value == "select" ) {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_blank(form_field, "default"),
        config_form_field_values_sql(form_field, "values", {
          required: true, non_blank: true
        }),
      ]
    } else if (selected_value == "radio") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_checkbox(form_field, "vertical_layout"),
        config_form_field_blank(form_field, "default"),
        config_form_field_values_sql(form_field, "values", {
          required: true, non_blank: true
        })
      ]
    } else if (selected_value == "collection_checkbox") {
      form_field.widgets = [
        config_form_field_minmax(form_field, "minselection", "maxselection"),
        config_form_field_checkbox(form_field, "vertical_layout"),
        config_form_field_values_sql(form_field, "values", {
          required: true, non_blank: true
        }),
        config_form_field_values_sql(form_field, "default_values", {
          non_blank: true
        }),
      ]
    } else if (selected_value == "single_checkbox") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "default_check"),
      ]
    } else if (selected_value == "text") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_input(form_field, "default"),
        config_form_field_input(form_field, "rows"),
        config_form_field_input(form_field, "cols"),
      ]
    } else if (selected_value == "student_field") {
      form_field.widgets = [
        config_form_field_student(form_field, "field"),
      ]
    } else if (selected_value == "city") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_checkbox(form_field, "state_required"),
        config_form_field_checkbox(form_field, "country_required"),
      ]
    } else if (selected_value == "residency") {
      form_field.widgets = [
        config_form_field_checkbox(form_field, "required"),
        config_form_field_checkbox(form_field, "number_required"),
      ]
    } else if (selected_value == "scholarity") {
      form_field.widgets = [
        config_form_field_values_sql(form_field, "values", {
          required: true, non_blank: true, label: "levels"
        }),
        config_form_field_values_sql(form_field, "statuses", {
          required: true, non_blank: true
        }),
        config_form_field_scholarity(form_field),
      ]
    } else if (selected_value == "html") {
      form_field.widgets = [
        config_form_field_codemirror(form_field, "html", "application/x-erb")
      ]
    } else if (selected_value == "code") {
      form_field.widgets = [
        config_form_field_codemirror(form_field, "code", "text/x-ruby")
      ]
    } else if (selected_value == "invalid") {
      form_field.widgets = [
        config_form_field_error(form_field, form_field.i18n_error("invalid_field"))
      ]
    }

    $(`#${form_field.baseid}`).html(form_field.widgets.map((el) => el.html).join(' '));
    form_field.widgets.forEach((el) => el.postRender())
    form_field.check_validity();
  }

  return form_field;
}


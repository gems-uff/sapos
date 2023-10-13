function config_form_field_minmax(form_field, minfield, maxfield) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let error_id = `${form_field.baseid}_minmax_error_${r}`
  let widgets = [
    config_form_field_input(form_field, minfield, "number"),
    config_form_field_input(form_field, maxfield, "number")
  ]
  return {
    html: `
      <dl id="${error_id}" class="form-field-config-error"></dl>
    ` + widgets.map((el) => el.html).join(' '),
    postRender: function () {
      widgets.forEach((el) => el.postRender())
    },
    validate: () => {
      let result = true;
      let selection_count_error = form_field.i18n_error("selection_count_error");
      let minselection = parseInt(form_field.data["minselection"] || "0")
      let maxselection = parseInt(form_field.data["maxselection"] || "0")
      if ((maxselection != 0) && minselection > maxselection) {
        $(`#${error_id}`).text(selection_count_error)
        $(`#${error_id}`).show();
        result = false;
      } else {
        $(`#${error_id}`).text("");
        $(`#${error_id}`).hide();
      }
      for (let widget of widgets) {
        result &= widget.validate();
      }
      return result;
    },
    refresh: () => {},
  }
}

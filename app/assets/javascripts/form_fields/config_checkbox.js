function config_form_field_checkbox(form_field, field, options) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let title = form_field.i18n(field)
  let id = `${form_field.baseid}_${field}_${r}`
  let checked = form_field.data[field] ? "checked" : "";
  return {
    html: `
      <dl>
        <dt><label for="${id}">${title}</label></dt>
        <dd><input type="checkbox" id="${id}" ${checked}></dd>
      </dl>
    `,
    postRender: function () {
      $(`#${id}`).on('change', function() {
        form_field.data[field] = this.checked;
        form_field.save_config();
        if (options["onchange"] != undefined) {
          options["onchange"](id, this.checked)
        }
      })
    },
    validate: () => true,
    refresh: () => {},
  }
}

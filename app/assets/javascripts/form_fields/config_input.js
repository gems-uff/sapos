function config_form_field_input(form_field, field, type) {
  let r = (Math.random() + 1).toString(36).substring(7);
  type = type || "text";
  let title = form_field.i18n(field);
  let id = `${form_field.baseid}_${field}_${r}`
  let value = form_field.data[field] || "";
  return {
    html: `
      <dl>
        <dt><label for="${id}">${title}</label></dt>
        <dd><input type="${type}" id="${id}" value="${value.replace(/"/g, '&quot;')}"></dd>
      </dl>
    `,
    postRender: function () {
      $(`#${id}`).on('change', function() {
        form_field.data[field] = $(this).val();
        form_field.save_config();
      })
    },
    validate: () => true,
    refresh: () => {},
  }
}

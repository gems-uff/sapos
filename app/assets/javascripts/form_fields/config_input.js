function config_form_field_input(form_field, field, type, options) {
  let r = (Math.random() + 1).toString(36).substring(7);
  type = type || "text";
  let title = form_field.i18n(field);
  let id = `${form_field.baseid}_${field}_${r}`
  if (!form_field.data[field] && options && (options["default"] != "")) {
    form_field.data[field] =  options["default"]
  }
  let value = form_field.data[field] || "";
  return {
    html: `
      <dl>
        <dt><label for="${id}">${title}</label></dt>
        <dd>
          <div id="${id}_error" class="form-field-config-error"></div>
          <input type="${type}" id="${id}" value="${value.replace(/"/g, '&quot;')}">
        </dd>
      </dl>
    `,
    postRender: function () {
      $(`#${id}`).on('change', function() {
        form_field.data[field] = $(this).val();
        form_field.save_config();
      })
    },
    validate: () => {
      let result = true;
      if (options && options["required"] && !form_field.data[field]) {
        let present_error = form_field.i18n_error(field + "_present_error");
        $(`#${id}_error`).text(present_error)
        $(`#${id}_error`).show();
        result = false;
      } else {
        $(`#${id}_error`).hide();
      }
      return result;
    },
    refresh: () => {},
  }
}

function config_form_field_select(form_field, field, selectable, options) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let title = form_field.i18n(field);
  let id = `${form_field.baseid}_${field}_${r}`
  let value = form_field.data[field] || "";

  let options_text = [];
  let found = null;
  for (let option of selectable) {
    let optvalue = option
    let optname = option
    if (Array.isArray(option)) {
      [optvalue, optname] = option
    }
    selected = "";
    if (value == optvalue) {
      selected = "selected"
      found = optvalue;
    }
    options_text.push(`
      <option value="${optvalue.replace(/"/g, '&quot;')}" ${selected}>
        ${optname}
      </option>
    `)
  }
  selected = ""
  if (found == null) {
    selected = "selected"
  }

  return {
    html: `
      <dl id="${id}-main">
        <dt><label for="${id}">${title}</label></dt>
        <dd>
          <select ${selected} id="${id}">
          <option value></option>
          ${options_text.join('')}
          </select>
          <div id="${id}_error" class="form-field-config-error"></div>
        </dd>
      </dl>
      <div id="${id}-extra"></div>
    `,
    postRender: function () {
      $(`#${id}`).on('change', function() {
        form_field.data[field] = $(this).val();
        if (options["onchange"] != undefined) {
          options["onchange"](id, $(this).val());
        }
        form_field.save_config();
      })
      if (found && options["onchange"] != undefined) {
        options["onchange"](id, found);
      }
    },
    validate: () => {
      let result = true;
      if (options["required"] && !form_field.data[field]) {
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

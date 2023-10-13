function config_form_field_blank(form_field, field) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let title = form_field.i18n(field);
  let title_title = form_field.i18n(field + "_blank_title");
  let id = `${form_field.baseid}_${field}_${r}`
  let check_value = "";
  let hide = "";
  if (form_field.data[field + "_check"]) {
    check_value = "checked";
  } else {
    hide = `style="display: none;"`;
  }
  let value = form_field.data[field] || "";

  return {
    html: `
      <dl>
        <dt><label for="${id}_check">${title}</label></dt>
        <dd>
          <input type="checkbox" id="${id}_check" ${check_value}>
          <input type="text" title="${title_title}" id="${id}" value="${value.replace(/"/g, '&quot;')}" ${hide}>
        </dd>

      </dl>
    `,
    postRender: function () {
      $(`#${id}_check`).on('change', function() {
        let checked = this.checked
        form_field.data[field + "_check"] = checked;
        $(`#${id}`).toggle(checked);
        form_field.save_config();
      })

      $(`#${id}`).on('change', function() {
        form_field.data[field] = $(this).val();
        form_field.save_config();
      })
    },
    validate: () => true,
    refresh: () => {},
  }
}
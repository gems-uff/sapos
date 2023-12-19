function config_form_field_condition(form_field, field, conditions) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let title = form_field.i18n(field);
  let id = `${form_field.baseid}_${field}_${r}`
  if (form_field.data[field] == null) {
    form_field.data[field] = {}
  }
  let errs = {};
  return {
    html: `
      <dl>
        <dt><label for="${id}">${title}</label></dt>
        <dd>
          <input id="${id}">
        </dd>
      </dl>
    `,
    postRender: function () {
      create_form_condition({
        id: id,
        attributes: form_field.data[field],
        condition_options: conditions,
        report_change: (attr, errors) => {
          errs = errors;
          form_field.save_config();
        }
      })
    },
    validate: () => {
      return Object.keys(errs).length == 0
    },
    refresh: () => {},
  }
}

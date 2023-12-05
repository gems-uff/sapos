function config_form_field_error(form_field, message) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let error_id = `${form_field.baseid}_error_${r}`
  return {
    html: `
      <dl id="${error_id}" class="form-field-config-error">${message}</dl>
    `,
    postRender: function () {},
    validate: () => {
      $(`#${error_id}`).show();
      return false;
    },
    refresh: () => {},
  }
}

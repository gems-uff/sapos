function config_form_field_scholarity(form_field) {
  let r = (Math.random() + 1).toString(36).substring(7);
  //let title = form_field.i18n(field);
  let fields = [
    "level", "status", "institution", "course", "location", "grade",
    "grade_interval", "start_date", "end_date"
  ]

  let id = `${form_field.baseid}_${r}`;
  let rows = []
  for (let field of fields) {
    let field_title = form_field.i18n("scholarity_" + field);
    let field_hide = form_field.data["scholarity_" + field + "_hide"] ? "checked" : "";
    let field_name = (form_field.data["scholarity_" + field + "_name"] || "").replace(/"/g, '&quot;');
    let field_desc = (form_field.data["scholarity_" + field + "_description"] || "").replace(/"/g, '&quot;');
    let field_required = form_field.data["scholarity_" + field + "_required"] ? "checked" : "";
    rows.push(`
      <tr>
        <th>${field_title}</th>
        <td><input type="checkbox" id="${id}_${field}_hide" ${field_hide}></td>
        <td><input id="${id}_${field}_name" placeholder="${field_title}" type="text" value="${field_name}"></td>
        <td><input id="${id}_${field}_description" type="text" value="${field_desc}"></td>
        <td><input type="checkbox" id="${id}_${field}_required" ${field_required}></td>
      </tr>
    `)
  }

  return {
    html: `
      <dl>
        <dt><label>${form_field.i18n("fields")}</label></dt>
        <dd>
          <table>
            <thead>
              <tr>
                <th>${form_field.i18n("field")}</th>
                <th>${form_field.i18n("hide")}</th>
                <th>${form_field.i18n("field_name")}</th>
                <th>${form_field.i18n("description")}</th>
                <th>${form_field.i18n("required")}</th>
              </tr>
            </thead>
            <tbody>
              ${rows.join('')}
            </tbody>
          </table>
        </dd>
      </dl>
    `,
    postRender: function () {
      for (let field of fields) {
        $(`#${id}_${field}_hide`).on('change', function() {
          form_field.data["scholarity_" + field + "_hide"] = this.checked;
          form_field.save_config();
        });

        $(`#${id}_${field}_name`).on('change', function() {
          form_field.data["scholarity_" + field + "_name"] = $(this).val();
          form_field.save_config();
        })

        $(`#${id}_${field}_description`).on('change', function() {
          form_field.data["scholarity_" + field + "_description"] = $(this).val();
          form_field.save_config();
        })

        $(`#${id}_${field}_required`).on('change', function() {
          form_field.data["scholarity_" + field + "_required"] = this.checked;
          form_field.save_config();
        });
      }
    },
    validate: () => true,
    refresh: () => {},
  }
}
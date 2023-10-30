function config_form_field_values_sql(form_field, field, options) {
  let values_id;
  let sql_id;
  let sql_visible = form_field.data[`${field}_use_sql`];
  let values_widget = config_form_field_values(form_field, field, { ...options,
    visible: !sql_visible
  })
  values_id = values_widget.main_id;
  let sql_widget = config_form_field_codemirror(form_field, `${field}_sql`, "text/x-mysql", { ...options,
    visible: !!sql_visible
  })
  sql_id = sql_widget.main_id;
  function onchange(id, checked) {
    $(`#${values_id}`).toggle(!checked)
    $(`#${sql_id}`).toggle(checked)
    sql_widget.refresh()
  }
  let checkbox_widget = config_form_field_checkbox(form_field, `${field}_use_sql`, {
    onchange
  })
  let widgets = [
    checkbox_widget,
    values_widget,
    sql_widget
  ]

  return {
    html: widgets.map((el) => el.html).join(' '),
    postRender: function () {
      widgets.forEach((el) => el.postRender())
    },
    validate: () => {
      if (form_field.data[`${field}_use_sql`]) {
        return sql_widget.validate();
      } else {
        return values_widget.validate();
      }
    },
    refresh: () => {
      widgets.forEach((el) => el.refresh())
    },
  }
}

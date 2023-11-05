function config_form_field_codemirror(form_field, field, mode, options) {
  options = options || {};
  let r = (Math.random() + 1).toString(36).substring(7);
  let visible = options["visible"] === false ? `style="display:none;"`: "";
  let main_id = `${form_field.baseid}_${field}_main_id_${r}`
  let label = options.label == undefined ? field : options.label + "_sql";
  let title = form_field.i18n(label);
  let id = `${form_field.baseid}_${field}_${r}`
  let value = form_field.data[field] || "";
  let editor;
  return {
    html: `
      <dl id="${main_id}" ${visible}>
        <dt><label for="${id}">${title}</label>
          <br>
          <span class="description">
          <span class="desc-title">${form_field.i18n(`${field}_description`)}</span>
          </span
        </dt>
        <dd>
          <div id="${id}_error" class="form-field-config-error"></div>
          <div><textarea id="${id}">${value}</textarea></div>
        </dd>
      </dl>
    `,
    postRender: function () {
      editor = CodeMirror.fromTextArea(document.getElementById(`${id}`), {
        mode: mode,
        indentWithTabs: true,
        smartIndent: true,
        lineNumbers: true,
        matchBrackets : true,
        autofocus: true
      })
      editor.on("change", function(cm, change){
        form_field.data[field] = cm.getValue();
        form_field.save_config();
      })
      editor.refresh();
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
    refresh: () => { editor.refresh() },
    main_id: main_id
  }
}

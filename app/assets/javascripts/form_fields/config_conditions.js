function config_form_field_conditions(form_field, field, conditions, options) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let visible = options["visible"] === false ? `style="display:none;"`: "";
  let main_id = `${form_field.baseid}_${field}_main_id_${r}`
  let div_id = `${form_field.baseid}_${field}_div_${r}`
  let add_id = `${form_field.baseid}_${field}_add_${r}`
  let label = options?.label ?? field;
  let title = form_field.i18n(label, "title");
  let add_title = form_field.i18n(label, "add");
  let field_title = form_field.i18n(label, "field");
  let condition_title = form_field.i18n(label, "condition");
  let value_title = form_field.i18n(label, "value");
  let values = form_field.data[field] || [];
  let elements = [];
  for (let value of values) {
    elements.push(`
      <tbody class="sub-form-record">
        <tr class="association-record">
          <td class="required">
            <input type="text" class="field-input text-input"
                   value="${(value["field"] || "").replace(/"/g, '&quot;')}">
          </td>
          <td class="required">
            <select class="condition-input">
              ${conditions.map((opt, i) => {
                let selected = opt == value["condition"] ? "selected" : ""
                let html_val = opt.replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
                return `<option value="${html_val}" ${selected}>${html_val}</option>`
              }).join('')}
            </select>
          </td>
          <td>
            <input type="text" class="value-input text-input"
                   value="${(value["value"] || "").replace(/"/g, '&quot;')}">
          </td>
          <td class="actions">
            <a class="destroy" href="#">Remove</a>
          </td>
          <td class="item-error form-field-config-error"></td>
        </tr>
      </tbody>
    `)
  }

  return {
    html: `
      <dl id="${main_id}" ${visible}>
        <dt><label>${title}</label></dt>
        <dd>
          <div id="${div_id}">
            <div class="main-error form-field-config-error"></div>
            <table>
              <thead>
                <tr>
                  <th class="field-column required"><label>${field_title}</label></th>
                  <th class="condition-column required"><label>${condition_title}</label></th>
                  <th class="value-column"><label>${value_title}</label></th>
                  <th></th>
                </tr>
              </thead>
              ${elements.join('')}
            </table>
            <div class="footer_wrapper">
              <div class="footer">
                <a id="${add_id}" class="as-js-button as_create_another"
                  style="" data-remote="true"
                  href="#">${add_title}</a>
              </div>
            </div>
          </div>
        </dd>
      </dl>
    `,
    postRender: () => {
      function getCurrValue() {
        return $(`#${div_id} table tbody`).map((i, el) => {
          return {
            field: $(el).find(".field-input").val() || "",
            condition: $(el).find(".condition-input").val() || "",
            value: $(el).find(".value-input").val() || ""
          }
        }).toArray();
      }

      $(`#${div_id} table input`).on('change', function() {
        form_field.data[field] = getCurrValue();
        form_field.save_config();
      })
      $(`#${div_id} table select`).on('change', function() {
        form_field.data[field] = getCurrValue();
        form_field.save_config();
      })


      $(`#${div_id} table a`).on('click', function() {
        $(this).closest('tbody').remove();
        form_field.data[field] = getCurrValue();
        form_field.save_config();
        return false;
      })

      $(`#${add_id}`).on('click', function() {
        let r = (Math.random() + 1).toString(36).substring(7);
        $(`#${div_id} table`).append(`
          <tbody class="sub-form-record" id="${form_field.baseid}_${field}_${r}">
            <tr class="association-record">
              <td class="required">
                <input type="text" class="field-input text-input">
              </td>
              <td class="required">
                <select class="condition-input">
                  ${conditions.map((opt, i) => {
                    let html_val = opt.replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
                    return `<option value="${html_val}">${html_val}</option>`
                  }).join('')}
                </select>
              </td>
              <td class="required">
                <input type="text" class="value-input text-input">
              </td>
              <td class="actions">
                <a class="destroy" href="#">Remove</a>
              </td>
              <td class="item-error form-field-config-error"></td>
            </tr>
          </tbody>
        `)
        $(`#${form_field.baseid}_${field}_${r} a`).on('click', function() {
          $(this).closest('tbody').remove();
          form_field.data[field] = getCurrValue();
          form_field.save_config();
          return false;
        })
        $(`#${form_field.baseid}_${field}_${r} input`).on('change', function() {
          form_field.data[field] = getCurrValue();
          form_field.save_config();
        })
        $(`#${form_field.baseid}_${field}_${r} select`).on('change', function() {
          form_field.data[field] = getCurrValue();
          form_field.save_config();
        })

        form_field.data[field] = getCurrValue();
        form_field.save_config();

        return false;
      })
    },
    validate: () => {
      is_required = options["required"]
      non_blank = options["non_blank"]
      let fielddata = form_field.data[field] || []
      let result = true;
      if (is_required && fielddata.length < 1) {
        let present_error = form_field.i18n_error(field + "_present_error")
        $(`#${div_id} .main-error`).text(present_error)
        $(`#${div_id} .main-error`).show()
        result = false;
      } else {
        $(`#${div_id} .main-error`).hide()
      }
      if (non_blank && fielddata.length > 0) {
        fielddata.forEach((el, i) => {
          let element = $($(`#${div_id} tbody tr`)[i]).find(".item-error");
          if ((el["field"].trim() == "") || (el["condition"].trim() == "")) {
            let blank_error = form_field.i18n_error(field + "_blank_error");
            element.text(blank_error)
            element.show()
            result = false;
          } else {
            element.hide()
          }
        })
      }

      return result;
    },
    main_id: main_id,
    refresh: () => {},
  }
}

function config_form_field_values(form_field, field, options) {
  let r = (Math.random() + 1).toString(36).substring(7);
  let visible = options["visible"] === false ? `style="display:none;"`: "";
  let main_id = `${form_field.baseid}_${field}_main_id_${r}`
  let div_id = `${form_field.baseid}_${field}_div_${r}`
  let add_id = `${form_field.baseid}_${field}_add_${r}`
  let title = form_field.i18n(field, "title");
  let add_title = form_field.i18n(field, "add");
  let values = form_field.data[field] || [];

  let elements = [];
  for (let value of values) {
    elements.push(`
      <tbody>
        <tr class="association-record">
          <td>
            <input type="text" value="${value.replace(/"/g, '&quot;')}">
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
      $(`#${div_id} table input`).on('change', function() {
        form_field.data[field] = $(`#${div_id} table input`).map((i, el) => $(el).val()).toArray();
        form_field.save_config();
      })

      $(`#${div_id} table a`).on('click', function() {
        $(this).closest('tbody').remove();
        form_field.data[field] = $(`#${div_id} table input`).map((i, el) => $(el).val()).toArray();
        form_field.save_config();
        return false;
      })

      $(`#${add_id}`).on('click', function() {
        let r = (Math.random() + 1).toString(36).substring(7);
        $(`#${div_id} table`).append(`
          <tbody id="${form_field.baseid}_${field}_${r}">
            <tr class="association-record">
              <td>
                <input type="text">
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
          form_field.data[field] = $(`#${div_id} table input`).map((i, el) => $(el).val()).toArray();
          form_field.save_config();
          return false;
        })
        $(`#${form_field.baseid}_${field}_${r} input`).on('change', function() {
          form_field.data[field] = $(`#${div_id} table input`).map((i, el) => $(el).val()).toArray();
          form_field.save_config();
        })

        form_field.data[field] = $(`#${div_id} table input`).map((i, el) => $(el).val()).toArray();
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
          if (el.trim() == "") {
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

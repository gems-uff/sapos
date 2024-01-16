function create_form_condition(options) {
  let parent_attributes = options.parent_attributes
  let report_change = options.report_change ?? function(attributes, errors){}
  let original = $(`#${options.id}`)
  let name = original.attr('name')
  let id = original.attr('id')
  let attributes = options.attributes ?? JSON.parse(original.val())
  let condition_options_map = {}
  let generated_fields = options.generated_fields ?? {}
  attributes.mode ??= (parent_attributes == null) ? "Nenhuma" : "Condição"
  attributes.field ??= ""
  attributes.condition ??= options.condition_options[0][0]
  attributes.value ??= ""
  attributes.form_conditions ??= []

  let errors = options.errors ?? {}

  let report = options.report ?? function(){
    report_change(attributes, errors)
    if (parent_attributes == null) {
      let error_element = $(`#${id} > .sub > .item-error`)
      if (Object.keys(errors).length == 0) {
        error_element.hide()
      } else {
        error_element.text(Object.values(errors)[0])
        error_element.show()
      }
    }
  }

  let mode_options = ["Condição", "E", "Ou"]
  if (parent_attributes == null) {
    mode_options.unshift("Nenhuma")
  }
  let optionsHTML = mode_options.map((opt) => `<option value="${opt}">${opt}</option>`)
  original.replaceWith(`
    <div id="${id}" class="form-condition-widget sub-form">
      <div class="mode">
        <select>${optionsHTML}</select>
      </div>
      <div class="sub"></div>
    </div>
  `)
  $(`#${id} > .mode > select`).on("change", function() {
    let value = $(this).val()
    if (value == "Nenhuma") {
      Object.keys(errors).forEach((key) => {
        delete errors[key]
      })
      $(`#${id} > .sub`).html(`
        <input type="hidden" name="${name}" value="" autocomplete="off">
        <div class="item-error form-field-config-error"></div>
      `)
    } else {
      let header = `
        <input type="hidden" name="${name}[mode]" value="${value}" autocomplete="off">
        <input type="hidden" name="${name}[form_conditions][0]" value="" autocomplete="off">
      `
      let remove_item = ``
      let error_report = ``
      if (attributes.id != undefined) {
        header += `<input type="hidden" name="${name}[id]" value="${attributes.id}" autocomplete="off">`
      }
      if (parent_attributes != null) {
        remove_item += `<a class="destroy" href="#">Remove</a>`
      } else {
        error_report = `<div class="item-error form-field-config-error"></div>`
      }

      if (value == "Condição") {
        Object.keys(errors).forEach((key) => {
          if (key.startsWith(`${name}[form_conditions]`)) {
            delete errors[key]
          }
        })
        if (attributes.form_conditions.length == 1 && attributes.form_conditions[0].mode == "Condição") {
          attributes.field = attributes.form_conditions[0].field
          attributes.condition = attributes.form_conditions[0].condition
          attributes.value = attributes.form_conditions[0].value
        }
        let field_input = $("<input/>", {
          name: `${name}[field]`, class: "field-input text-input", type: "text",
          required: "required", placeholder: "Campo", title: "Campo",
          value: attributes.field
        })
        let condition_input = $("<select/>", {
          name: `${name}[condition]`, class: "condition-input",
          html: options.condition_options.map((opt) => {
            condition_options_map[opt[0]] = opt[1]
            let optAttr = {
              text: opt[0], value: opt[0],
              selected: (opt[0] == attributes.condition)
            }
            return $("<option/>", optAttr).outerHTML();
          })
        })
        let value_input = $("<input/>", {
          name: `${name}[value]`, class: "value-input text-input", type: "text",
          placeholder: "Valor", title: "Valor", value: attributes.value
        })

        $(`#${id} > .sub`).html(`
          ${header}
          ${field_input.outerHTML()}
          ${condition_input.outerHTML()}
          ${value_input.outerHTML()}
          ${remove_item}
          ${error_report}
        `)
        $(`#${id} > .sub > .field-input`).autocomplete({
          source: autocomplete_search("/form_autocompletes/form_field")
        })
        let on_change = function(inputfield, validate) {
          $(`#${id} > .sub > .${inputfield}-input`).on("change", function() {
            let val = $(this).val()
            attributes[inputfield] = val
            if (attributes.form_conditions.length == 1) {
              attributes.form_conditions[0][inputfield] = val
            }
            if (validate != undefined) {
              validate(val)
            }
            report()
          })
          $(`#${id} > .sub > .${inputfield}-input`).change();
        }
        on_change("field", (val) => {
          if (val.trim() == "") {
            errors[`${name}[field]`] = "Campo não pode ficar em branco"
          } else {
            delete errors[`${name}[field]`]
          }
        })
        on_change("condition", (val) => {
          if (condition_options_map[val] == 0) {
            $(`#${id} > .sub > .value-input`).hide()
          } else {
            $(`#${id} > .sub > .value-input`).show()
          }
        });
        on_change("value");
      } else if ((value == "E") || (value == "Ou")) {
        delete errors[`${name}[field]`]
        if (attributes.form_conditions.length == 0) {
          attributes.form_conditions = [{
            mode: "Condição",
            field: attributes.field,
            condition: attributes.condition,
            value: attributes.value,
          }]
        }
        let children = []
        let items = attributes.form_conditions.map((condition) => {
          return create_condition_item(
            id, name, condition, children, generated_fields
          )
        }).join("")
        $(`#${id} > .sub`).html(`
          ${header}
          <a href="#" class="add-condition">Adicionar condição</a>
          ${remove_item}
          <div class="items">
            ${items}
          </div>
          ${error_report}
        `)
        children.forEach((element) => {
          create_form_condition({
            id: element[0] + "-input",
            attributes: element[1],
            condition_options: options.condition_options,
            errors: errors,
            report: report,
            parent_attributes: attributes,
            generated_fields: generated_fields
          })
        })
        $(`#${id} > .sub > .add-condition`).on("click", function(){
          let newChild = []
          let newAttributes = {}
          attributes.form_conditions.push(newAttributes)
          let child = create_condition_item(
            id, name, newAttributes, newChild, generated_fields
          );
          $(`#${id} > .sub > .items`).append(child)
          create_form_condition({
            id: newChild[0][0] + "-input",
            attributes: newAttributes,
            condition_options: options.condition_options,
            errors: errors,
            report: report,
            parent_attributes: attributes,
            generated_fields: generated_fields
          })
          return false;
        })
      }
      $(`#${id} > .sub > a.destroy`).on("click", function() {
        $(this).closest(`#${id}`).remove();
        Object.keys(errors).forEach((key) => {
          if (key.startsWith(`${name}`)) {
            delete errors[key]
          }
        })
        if (parent_attributes != null) {
          let parent_conditions = parent_attributes.form_conditions
          let index = parent_conditions.indexOf(attributes)
          parent_conditions.splice(index, 1)
          report()
        }
        return false
      })
    }
    attributes.mode = value
    report()
  })
  $(`#${id} > .mode > select`).val(attributes.mode).change();
}

function create_condition_item(
  parent_id, parent_name, attributes, children, generated_fields
) {
  let temp_id = attributes.id ?? attributes.temp_id
  if (temp_id == null) {
    temp_id = Date.now()
    while (generated_fields[temp_id] != undefined) {
      temp_id += 1
    }
    generated_fields[temp_id] = 1
  }
  attributes.temp_id = temp_id
  let new_name = `${parent_name}[form_conditions][${temp_id}]`
  let new_id = `${parent_id}-form-conditions-${temp_id}`
  let input = $(`<input/>`, {
    name: new_name,
    id: `${new_id}-input`,
  })
  children.push([new_id, attributes])
  return input.outerHTML()
}

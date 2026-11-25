$(function() {
  function rowOf(el) {
    return $(el).closest('tr, .as_form, form');
  }
  function changeSituationInput(context, situation){
    if (!situation) return;
    var situationSelect = rowOf(context).find('.situation-input');
    if(situationSelect.val() != situation){
      situationSelect.val(situation).trigger('change');
    }
  }

  $(document).on('change', '.disapproved_by_absence-input', function() {
    if (!this.checked) return;
    var target_row = rowOf(this);
    var gradeInput = target_row.find(".grade-input");
    var disapproved_label = this.getAttribute('data_disapproved') || gradeInput.attr('data_disapproved');
    if (this.getAttribute("course_has_grade") == "true") {
      var grade_for_absence = this.getAttribute("grade_of_disapproval_for_absence");
      if (grade_for_absence) {
        var grade = gradeInput.val().replace(/\s+/g, '').replace(",", ".");
        if (grade == ""){
          gradeInput.val(grade_for_absence).trigger("input");
        }
        else{
          var msg = this.getAttribute('overwrite_confirm_msg').replace('%{actual_grade}', grade.replace('.', ',')).replace('%{grade_for_disapproval}', grade_for_absence.replace('.', ','));
          if(confirm(msg)){
            gradeInput.val(grade_for_absence).trigger("input");
          }
          else{
            this.checked = false;
            return;
          }
        }
      }
    }
    changeSituationInput(target_row, disapproved_label);
  });
  $(document).on('change', '.grade_not_count_in_gpr-input', function() {
    if (this.checked) return;

    var row = rowOf(this);

    if (row.find('.disapproved_by_absence-input').is(':checked')) return;

    var gradeInput = row.find('.grade-input');

    if (gradeInput.val() !== ''){ gradeInput.trigger('input');}
  });

  $(document).on('focus','.grade-input',function(){
    $(this).attr('placeholder', this.getAttribute('grade_placeholder'));
  });
  $(document).on('blur','.grade-input',function(){
    $(this).attr('placeholder','');
  });
  $(document).on('input', '.grade-input', function() {
    var input = this;
    var target_row = rowOf(this);
    var not_count_checkbox = target_row.find(".grade_not_count_in_gpr-input");
    var not_counting = not_count_checkbox.length > 0 && not_count_checkbox.is(":checked");
    var cursorPos = input.selectionStart;
    var oldLength = input.value.length;
    var digits = $(this).val().replace(/\D/g, '');
    if (digits === ''){
      if (!not_counting) {
        changeSituationInput($(this), this.getAttribute('data_registered'));
      }
      return;
    }
    var number = parseInt(digits, 10);
    if (number > 100){
      number = 100;
    }
    var formatted = (number / 10).toFixed(1).replace('.', ',');
    $(this).val(formatted);
    var newLength = formatted.length;
    var newCursorPos = cursorPos + (newLength - oldLength);
    newCursorPos = Math.max(0, Math.min(newCursorPos,newLength));
    input.setSelectionRange(newCursorPos,newCursorPos);
    if (not_counting) {
      return;
    }

    var minimum_grade = this.getAttribute('minimum_grade_for_approval');
    var actual_grade = parseFloat(formatted.replace(',','.'));
    if(actual_grade >= minimum_grade){
      changeSituationInput($(this), this.getAttribute('data_approved'));
    }
    else{
      changeSituationInput($(this), this.getAttribute('data_disapproved'));
    }
  });
  $(document).on('keydown','.grade-input',function(e){
    if (e.which == 40 || e.which == 38){
      var subform = $(this).closest('.class_enrollments-sub-form');
      var gradeInputs = subform.find('.grade-input:visible');
      var index = gradeInputs.index(this);
      var nextIndex = (e.which==40) ? index + 1 : index - 1;
      if(nextIndex >= 0 && nextIndex < gradeInputs.length){
        var nextEl = gradeInputs.eq(nextIndex);
        nextEl.focus();
        /* 10ms timeout to make sure the select() works properly */
        setTimeout(function(){
          nextEl.select();
        }, 10);
      }
    }
    else if (e.which == 8 || e.which == 46){
      var input = this;
      if (input.selectionStart !== input.selectionEnd){
        return;
      }
      if (/^0[,.]\d$/.test($(this).val())){
        e.preventDefault();
        $(this).val('').trigger('input');
      }
    }
  });
});

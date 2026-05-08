$(function() {
  $(document).on('change', '.disapproved_by_absence-input', function() {
    if(this.checked){
      var course_has_grade = this.getAttribute("course_has_grade");
      var target_row = $(this).closest("tr");
      if (course_has_grade == "true") {
        var grade_of_disapproval_for_absence = this.getAttribute("grade_of_disapproval_for_absence");
        if (grade_of_disapproval_for_absence != "") {
          var grade = target_row.find(".grade-input").val();
          if (grade == "" || parseFloat(grade)== 0){
            target_row.find(".grade-input").val(grade_of_disapproval_for_absence).trigger("input");
          }
          else if (parseFloat(grade) != parseFloat(grade_of_disapproval_for_absence)){
            var msg = "Já existe uma nota digitada ("+grade.replace('.',',')+"). "+
            "Deseja sobrescrevê-la com a nota de reprovação por falta (" + grade_of_disapproval_for_absence.replace('.',',') + ")?";
            if(confirm(msg)){
              target_row.find(".grade-input").val(grade_of_disapproval_for_absence).trigger("input");
            }
            else{
              this.checked = false;
            }
          }
        }
      }
      else{
        changeSituationInput(target_row,"Reprovado");
      }
    }
  });
  function changeSituationInput(context,situation){
    var row = context.closest('tr');
    var situationSelect = row.find('.situation-input');
    if(situationSelect.val() != situation){
      situationSelect.val(situation).trigger('change');
    }
  }
  $(document).on('focus','.grade-input',function(){
    $(this).attr('placeholder','_,_');
  });
  $(document).on('blur','.grade-input',function(){
    $(this).attr('placeholder','');
  });
  $(document).on('input', '.grade-input', function() {
    var digits = $(this).val().replace(/\D/g, '');
    if (digits === '') return;
    var number = parseInt(digits, 10);
    var formatted = (number / 10).toFixed(1).replace('.', ',');
    $(this).val(formatted);
    var minimum_grade = this.getAttribute('minimum_grade_for_approval');
    var actual_grade = parseFloat(formatted.replace(',','.'));
    if(actual_grade <= 10){ /* sanity check */
      if(actual_grade >= minimum_grade){
        changeSituationInput($(this),"Aprovado");
      }
      else{
        changeSituationInput($(this),"Reprovado");
      }
    }
  });
  $(document).on('as:action_success', function() {
    $('.class_enrollments-sub-form').each(function() {
      var subform = $(this);
      if (subform.find('[course_has_grade="false"]').length>0){
        subform.addClass('hide-score-column');
      }
      else{
        subform.find('.grade-input').val(function(i,value){
          return value.replace('.',',');
        });
      }
    });
  });
});

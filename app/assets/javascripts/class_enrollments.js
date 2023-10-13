$(function() {
  $(document).on('change', '.disapproved_by_absence-input', function() {
    if(this.checked){
      var course_has_grade = this.getAttribute("course_has_grade");
      if (course_has_grade == "true") {
        var grade_of_disapproval_for_absence = this.getAttribute("grade_of_disapproval_for_absence");
        grade_of_disapproval_for_absence = grade_of_disapproval_for_absence.replace(/\s+/g, '').replace(",", ".");
        if (grade_of_disapproval_for_absence != "") {
          grade_of_disapproval_for_absence = parseFloat(grade_of_disapproval_for_absence);
          var class_enrollments_id = this.getAttribute("class_enrollments_id");
          var grade = document.getElementById( "record_grade_" + class_enrollments_id ).value;
          grade = grade.replace(/\s+/g, '').replace(",", ".");
          if (grade == "") {
            document.getElementById("record_grade_" + class_enrollments_id).value = grade_of_disapproval_for_absence;
          } else {
            grade = parseFloat(grade);
            if( grade > grade_of_disapproval_for_absence ){
              document.getElementById("record_grade_" + class_enrollments_id).value = grade_of_disapproval_for_absence;
            }
          }
        }
      }
    }
  });
});

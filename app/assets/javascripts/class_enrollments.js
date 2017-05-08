$(function() {
  $(document).on('change', '.disapproved_by_absence-input', function() {

    if(this.checked){
      var grade_of_disapproval_for_absence = this.getAttribute("grade_of_disapproval_for_absence");	   
      grade_of_disapproval_for_absence = grade_of_disapproval_for_absence.replace(/\s+/g, '').replace(",", ".");
      if( grade_of_disapproval_for_absence != "" ){	     
        grade_of_disapproval_for_absence = parseFloat(grade_of_disapproval_for_absence);
        var class_enrollments_id = this.getAttribute("class_enrollments_id");
        var grade = document.getElementById( "record_grade_" + class_enrollments_id ).value;
        grade = grade.replace(/\s+/g, '').replace(",", ".");   
        if(grade == ""){
          document.getElementById("record_grade_" + class_enrollments_id).value = grade_of_disapproval_for_absence;
        }else{ 
          grade = parseFloat(grade);
          if( grade > grade_of_disapproval_for_absence ){
            document.getElementById("record_grade_" + class_enrollments_id).value = grade_of_disapproval_for_absence;      
          }
        }
      }
    }

  });
});



/*
$(function() {
  $(document).on('change', '.disapproved_by_absence-input', function() {
    // this == the element that fired the change event
    alert('Mudou o checkbox9');
    alert(this.checked);
    //alert(document.getElementById("record_grade_1").value)
    //alert(this.class_enrollments_id);
    //alert(this.grade_of_disapproval_for_absence);	  
    //alert(this.toSource());
    //alert(JSON.stringify(this));

    //alert(this.getAttribute("class_enrollments_id"));
    //alert(this.getAttribute("grade_of_disapproval_for_absence"));

    var class_enrollments_id = this.getAttribute("class_enrollments_id");
    var grade_of_disapproval_for_absence = this.getAttribute("grade_of_disapproval_for_absence");	   
    var grade = document.getElementById( "record_grade_" + class_enrollments_id ).value;

    alert(class_enrollments_id);
    alert(grade_of_disapproval_for_absence);
    alert(grade);	  

    if(this.checked){
      alert("entrou no if. vai fazer o parse e comparar");
      grade = grade.replace(/\s+/g, '').replace(",", ".");   
   
      if( grade_of_disapproval_for_absence != "" ){	     

        grade = parseFloat(grade);
        grade_of_disapproval_for_absence = grade_of_disapproval_for_absence.replace(/\s+/g, '').replace(",", ".");
        grade_of_disapproval_for_absence = parseFloat(grade_of_disapproval_for_absence);

        alert("os parses");	      
        alert(grade);
        alert(grade_of_disapproval_for_absence);	    
    
        if( grade > grade_of_disapproval_for_absence ){
          alert("entrou no if para trocar o valor do campo");
	  document.getElementById("record_grade_" + class_enrollments_id).value = grade_of_disapproval_for_absence;      
        }

      }	      


    } 

    //class_enrollments_id="2" grade_of_disapproval_for_absence="10"

   });
});
*/


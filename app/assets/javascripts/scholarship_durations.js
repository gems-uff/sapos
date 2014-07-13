(function($) {
  function add_replace_date_input(adapter) {
    var input = $('.replace-date-input', adapter || document);
    if (!input.length) return;
    $('.replace-date-input').on('change', function(e){
      var id = $(this).attr('id');
      console.log(id);
      var subname = id.slice(0, -2);
      var month = subname + '2i';
      var year = subname + '1i';
      var hidden_input = $(this).nextAll('input').first();
      var yvalue = $("#"+year).val();
      var mvalue = $("#"+month).val() - 1;
      
      var new_date = $.datepicker.formatDate($.datepicker.regional['pt-BR'].dateFormat, new Date(yvalue, mvalue, 1));
      hidden_input.val(new_date);
    })
    $('.replace-date-input').each(function(){
      var name = $(this).attr('name');
      $("input[name='"+name.replace(/\(.i\)/g, "(3i)")+"']").attr('name', '');
      $(this).attr('name', '');
    })
  }

  // as:action_success => action link is clicked and form is open (form is in action_link.adapter)
  $(document).on('as:action_success', 'a.as_action', function(e, action_link) {
    if (action_link.adapter) {
      add_replace_date_input(action_link.adapter);
    }
  });
  // as:element_updated => form updated because validations fail
  //                       form field changed because a chained field changed
  //                       ajax inplace edit is open
  //                       singular subform is replaced
  //                       list is refreshed
  // as:element_created => subform record in a plural subform is added
  $(document).on('as:element_updated as:element_created', function(e) {
    add_replace_date_input(e.target);
    
  });
  $(document).ready(function() {
    add_replace_date_input();
  });
})(jQuery);
(function($) {
  function add_carrierwave_preview(adapter) {
    carrierwave_preview('.students-view', $('.photo-input', adapter || document));
  }

  // as:action_success => action link is clicked and form is open (form is in action_link.adapter)
  $(document).on('as:action_success', 'a.as_action', function(e, action_link) {
    if (action_link.adapter) {
      add_carrierwave_preview(action_link.adapter);
    }
  });
  // as:element_updated => form updated because validations fail
  //                       form field changed because a chained field changed
  //                       ajax inplace edit is open
  //                       singular subform is replaced
  //                       list is refreshed
  // as:element_created => subform record in a plural subform is added
  $(document).on('as:element_updated as:element_created', function(e) {
    add_carrierwave_preview(e.target);
    
  });
  $(document).ready(function() {
    add_carrierwave_preview();
  });
})(jQuery);
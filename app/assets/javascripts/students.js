(function($) {
  function add_carrierwave_preview(adapter) {
    var input = $('.photo-input', adapter || document);
    if (!input.length) return;
    carrierwave_preview('.students-view', input);
    input.after(
      '<div style="margin-left: 2px;">'+
        '<input autocomplete="off" class="photo-input text-input" id="'+ input.attr('id') +'_" name="record[photo_][base64_contents]" type="hidden">' +
        '<input autocomplete="off" class="photo-input text-input" id="'+ input.attr('id') +'_filename" name="record[photo_][filename]" type="hidden" value="camera.jpg">' +
        '<div class="camera" style="width: 400px; height: 300px;"></div>'+
        '<a href="#" class="takesnapshot" style="display:block; margin: 3px 0;"> Tirar foto </a>'+
        '<a href="#" class="togglewebcam" style="display:block; margin: 3px 0;"> Webcam </a>'+
        '<a href="#" class="togglefile" style="display:none; margin: 3px 0;"> Arquivo </a>'+
      '</div>'
    );
    var camerainput = $('#' + input.attr('id') + '_');
    var camerainputname = $('#' + input.attr('id') + '_filename');

    var webcam = $('.camera', adapter || document);
    var toggletakesnapshot = $('.takesnapshot', adapter || document);
    webcam.hide();
    toggletakesnapshot.hide();
    var init = false;
    var togglewebcam = $('.togglewebcam', adapter || document);
    var togglefile = $('.togglefile', adapter || document);
        
    var toggler = function(e){
      e.preventDefault();
      webcam.toggle();
      togglewebcam.toggle();
      togglefile.toggle();
      toggletakesnapshot.toggle();
      input.toggle();
      if (webcam.is(":visible")) {
        if (!init) {
          Webcam.attach(webcam[0]);
          init = true;
        }
        camerainput.attr('name', 'record[photo][base64_contents]');
        camerainputname.attr('name', 'record[photo][filename]');
        input.attr('name', 'record[photo_]');
        
      } else {
        camerainput.attr('name', 'record[photo_][base64_contents]');
        camerainputname.attr('name', 'record[photo_][filename]');
        input.attr('name', 'record[photo]');
      }
    }

    togglewebcam.on('click', toggler);
    togglefile.on('click', toggler);
    toggletakesnapshot.on('click', function(e) {
      e.preventDefault();
      var data_uri = Webcam.snap();
      $('.previewimage', adapter || document).html(['<p>Visualização:</p><img class="thumb" src="', data_uri,
                                        '" title="photo"/>'].join(''));
      var raw_image_data = data_uri.replace(/^data\:image\/\w+\;base64\,/, '');
      camerainput.val(raw_image_data);
      camerainputname.val((new Date().getTime()) + '.jpg');
      $('input[name="record[remove_photo]"]', adapter || document).val('false');
    });
     
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
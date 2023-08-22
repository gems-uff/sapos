function carrierwave_preview(as_container, input, previous_url) {
  // Show previously loaded image
  var a = $(as_container + ' .carrierwave_controls a')[0];
  if (a){
    $(a).html('<img src="'+previous_url+'" class="preview-previous" />');
    a.nextSibling.remove();
    $(a).css('display', 'block');
  }

  // Load image preview
  input.after("<div class='previewimage' style='margin-left: 2px;'></div>")
  input.change(function(ev){
    var f = (ev.target.files[0]);
    if (window.File && window.FileReader && window.FileList && window.Blob) {
      var reader = new FileReader();

      reader.onload = (function(theFile) {
        return function(e) {
          $(as_container + ' .previewimage').html([
            '<p>Visualização:</p><img class="thumb" src="', e.target.result,
            '" title="', escape(theFile.name),
            '" ' + img_style + ' />'
          ].join(''));
        };
      })(f);

      reader.readAsDataURL(f);
    } else {
      $(as_container + ' .previewimage').html('');
    }
  })
}

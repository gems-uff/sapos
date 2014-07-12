function carrierwave_preview(as_container, input) {
	
	// Show previously loaded image
	var a = $(as_container + ' .carrierwave_controls a')[0];
	if (a){
		var img_src = a.textContent;
		$(a).html('<img src="'+img_src+'"/>');
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
                    $(as_container + ' .previewimage').html(['<p>Visualização:</p><img class="thumb" src="', e.target.result,
                                    '" title="', escape(theFile.name), '"/>'].join(''));
                };
            })(f);

            reader.readAsDataURL(f);
        } else {
            $(as_container + ' .previewimage').html('');
        }
    })
}
function carrierwave_preview(as_container) {
	// Show previously loaded image
	var a = $(as_container + ' .carrierwave_controls a')[0];
	if (a){
		var img_src = a.textContent;
		$(a).html('<img src="'+img_src+'"/>');
		a.nextSibling.remove();
		$(a).css('display', 'block');
	}

	// Load image preview
	input = $(as_container + ' .image-input')
	input.after("<div class='previewimage'></div>")
	input.change(function(ev){
	    var f = (ev.target.files[0]);
        if (window.File && window.FileReader && window.FileList && window.Blob) {
            var reader = new FileReader();

            reader.onload = (function(theFile) {
                return function(e) {
                    $(as_container + ' .previewimage').html(['<img class="thumb" src="', e.target.result,
                                    '" title="', escape(theFile.name), '"/>'].join(''));
                };
            })(f);

            reader.readAsDataURL(f);
        } else {
            $(as_container + ' .previewimage').html('');
        }
    })
}
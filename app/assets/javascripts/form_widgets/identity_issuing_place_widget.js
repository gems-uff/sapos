

function identityIssuingPlaceWidget() {
	var toggleLink = function() {
		var value = this.value;
		var hideId = $(this).data("hide");
		var show1Id = $(this).data("show1");
		var show2Id = $(this).data("show2");
		$(this).hide();
		$(hideId).hide();
		$(show1Id).show();
		$(show2Id).show();
		return false;
	};

	$('#main_content').on('change', '.identity_issuing_place_widget_select', function() {
		var value = this.value;
		var textDomId = $(this).data("text-field-id");
		$(textDomId).val(value);
	});
	$('#main_content').on('click', '.identity_issuing_place_widget_show_state', toggleLink);
	$('#main_content').on('click', '.identity_issuing_place_widget_show_text', toggleLink);

}
var I18nSelectState = "Selecione o estado";
var I18nSelectCity = "Selecione a cidade";

function replaceList(url, domElement, defaultText, done) {
	$(domElement).siblings(".loading-indicator").css('visibility', 'visible');
	$.getJSON(url, function (json) {
		stateList = "<option value=\"-1\">"+defaultText+"</option>"
	    $.each(json, function (i, tuple) {
	        stateList += "<option value=\""+ tuple[1] +"\">" + tuple[0] + "</option>";
	    });
	    $(domElement).html(stateList);
	    done();
	    $(domElement).siblings(".loading-indicator").css('visibility', 'hidden');
	});
}

function cityWidget() {
	$('#main_content').on('change', '.city_widget_country', function() {
		countryId = this.value;
		stateDomId = $(this).data("state-dom-id");
		cityDomId = $(this).data("city-dom-id");
		url = $(this).data("access-url").replace("*", countryId);
		replaceList(url, stateDomId, I18nSelectState, function() {
			$(cityDomId).html("<option value>"+I18nSelectCity+"</option>");
		});		
	});

	$('#main_content').on('change', '.city_widget_state', function() {
		stateId = this.value;
		cityDomId = $(this).data("city-dom-id");
		url = $(this).data("access-url").replace("*", stateId);
		replaceList(url, cityDomId, I18nSelectCity, function() {});		
	});
}
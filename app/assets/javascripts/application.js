// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.ui.all
//= require jquery_ujs
//= require active_scaffold
//= require_tree .


var I18nExitConfirmation = 'Existem campos preenchidos! Você pode perder suas alterações!';
var I18nSelectState = "Selecione o estado";
var I18nSelectCity = "Selecione a cidade";

function areInputsFilled(selector) {
	var filled = false;
	$(selector).each(function() {
	   var element = $(this);
	   if (element.val() != "") {
	       filled = true;
	   }
	});
	return filled;
}

function confirmOnPageExit() {
	if (areInputsFilled('.as_form.update input[type=text], .as_form.create input[type=text]')) {
		return I18nExitConfirmation;
	}
}


function replaceList(url, domElement, defaultText, done) {
	$(domElement).siblings(".loading-indicator").css('visibility', 'visible');
	$.getJSON(url, function (json) {
		stateList = "<option value>"+defaultText+"</option>"
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

$(document).ready(function(){
	window.onbeforeunload = confirmOnPageExit;
	cityWidget();
});
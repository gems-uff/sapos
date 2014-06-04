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
//= require codemirror
//= require codemirror/modes/sql
//= require codemirror/modes/xml
//= require_tree .


var I18nExitConfirmation = 'Existem campos preenchidos! Você pode perder suas alterações!';

function areInputsFilled(selector) {
  var filled = false;
  $(selector).each(function () {
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

function prevSemester(date) {
  return new Date(date.getTime() - DAY_IN_MILLISECONDS * 180);
}

function nextSemester(date) {
  return new Date(date.getTime() + DAY_IN_MILLISECONDS * 180);
}

function addToQueryString(url, key, value) {
  var query = url.indexOf('?');
  var anchor = url.indexOf('#');
  if (query == url.length - 1) {
    // Strip any ? on the end of the URL
    url = url.substring(0, query);
    query = -1;
  }
  return (anchor > 0 ? url.substring(0, anchor) : url)
    + (query > 0 ? "&" + key + "=" + value : "?" + key + "=" + value)
    + (anchor > 0 ? url.substring(anchor) : "");
}


function queryStringToHash(query) {

  if (query == '') return null;

  var hash = {};

  var vars = query.split("&");

  for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    var k = decodeURIComponent(pair[0]);
    var v = decodeURIComponent(pair[1]);

    // If it is the first entry with this name
    if (typeof hash[k] === "undefined") {

      if (k.substr(k.length - 2) != '[]')  // not end with []. cannot use negative index as IE doesn't understand it
        hash[k] = v;
      else
        hash[k] = [v];

      // If subsequent entry with this name and not array
    } else if (typeof hash[k] === "string") {
      hash[k] = v;  // replace it

      // If subsequent entry with this name and is array
    } else {
      hash[k].push(v);
    }
  }
  return hash;
};

$(document).ready(function () {
  $.datepicker.regional['pt-BR'].dateFormat = 'yy-mm-dd';
  $.datepicker.setDefaults($.datepicker.regional['pt-BR'] );

  window.onbeforeunload = confirmOnPageExit;
  cityWidget();
  identityIssuingPlaceWidget();
});


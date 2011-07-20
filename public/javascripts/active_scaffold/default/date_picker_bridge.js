jQuery(function($){
  if (typeof($.datepicker) === 'object') {
    $.datepicker.regional['pt'] = {"nextText":"Next","changeMonth":true,"prevText":"Previous","closeText":"Close","monthNamesShort":["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"],"changeYear":true,"dayNames":["Domingo","Segunda","Ter\u00e7a","Quarta","Quinta","Sexta","S\u00e1bado"],"dateFormat":"dd/mm/yy","dayNamesMin":["Dom","Seg","Ter","Qua","Qui","Sex","S\u00e1b"],"dayNamesShort":["Dom","Seg","Ter","Qua","Qui","Sex","S\u00e1b"],"currentText":"Today","monthNames":["Janeiro","Fevereiro","Mar\u00e7o","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]};
    $.datepicker.setDefaults($.datepicker.regional['pt']);
  }
  if (typeof($.timepicker) === 'object') {
    $.timepicker.regional['pt'] = {"ampm":false,"secondText":"Segundo","minuteText":"Minuto","dateFormat":"DD, dd de %B de yy, ","timeFormat":"hh:mm h","hourText":"Hora"};
    $.timepicker.setDefaults($.timepicker.regional['pt']);
  }
});
$(document).ready(function() {
  $('input.date_picker').live('focus', function(event) {
    var date_picker = $(this);
    if (typeof(date_picker.datepicker) == 'function') {
      if (!date_picker.hasClass('hasDatepicker')) {
        date_picker.datepicker();
        date_picker.trigger('focus');
      }
    }
    return true;
  });
  $('input.datetime_picker').live('focus', function(event) {
    var date_picker = $(this);
    if (typeof(date_picker.datetimepicker) == 'function') {
      if (!date_picker.hasClass('hasDatepicker')) {
        date_picker.datetimepicker();
        date_picker.trigger('focus');
      }
    }
    return true;
  });
});
jQuery(function($){
  if (typeof($.datepicker) === 'object') {
    $.datepicker.regional['en'] = {"prevText":"Previous","closeText":"Close","showMonthAfterYear":false,"monthNamesShort":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"nextText":"Next","changeMonth":true,"firstDay":0,"weekHeader":"Wk","changeYear":true,"isRTL":false,"dateFormat":"yy-mm-dd","dayNames":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],"dayNamesMin":["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],"dayNamesShort":["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],"currentText":"Today","monthNames":["January","February","March","April","May","June","July","August","September","October","November","December"]};
    $.datepicker.setDefaults($.datepicker.regional['en']);
  }
  if (typeof($.timepicker) === 'object') {
    $.timepicker.regional['en'] = {"ampm":false,"secondText":"Seconds","minuteText":"Minute","dateFormat":"D, dd M yy ","timeFormat":"hh:mm:ss","hourText":"Hour"};
    $.timepicker.setDefaults($.timepicker.regional['en']);
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
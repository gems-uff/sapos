jQuery(function ($) {
    if (typeof($.datepicker) === 'object') {
        $.datepicker.regional['pt'] = {"prevText": "Anterior", "nextText": "Pr\u00f3ximo", "changeMonth": true, "monthNames": ["Janeiro", "Fevereiro", "Mar\u00e7o", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"], "changeYear": true, "closeText": "Fechar", "dayNames": ["Domingo", "Segunda", "Ter\u00e7a", "Quarta", "Quinta", "Sexta", "S\u00e1bado"], "dateFormat": "dd-mm-yy", "currentText": "Today", "monthNamesShort": ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"], "dayNamesShort": ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "S\u00e1b"], "dayNamesMin": ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "S\u00e1b"]};
        $.datepicker.setDefaults($.datepicker.regional['pt']);
    }
    if (typeof($.timepicker) === 'object') {
        $.timepicker.regional['pt'] = {  timeFormat: "hh:mm", currentText: "Agora", closeText: "OK", timeSuffix: "h",
            timeOnlyTitle: "Escolha a Hora", timeText: "Hora escolhida", hourText: "Hora", minuteText: "Minuto", timeOnly: true
        };
        $.timepicker.setDefaults($.timepicker.regional['pt']);
    }
});
$(document).ready(function () {
    $('form.as_form, form.inplace_form').live('as:form_loaded', function (event) {
        var as_form = $(this).closest("form");
        as_form.find('input.datetime_picker').each(function (index) {
            var date_picker = $(this);
            if (typeof(date_picker.datetimepicker) == 'function') {
                date_picker.datetimepicker();
            }
        });

        as_form.find('input.date_picker').each(function (index) {
            var date_picker = $(this);
            if (typeof(date_picker.datepicker) == 'function') {
                date_picker.datepicker();
            }
        });

        as_form.find('input.time_picker').each(function (index) {
            var date_picker = $(this);
            if (typeof(date_picker.timepicker) == 'function') {
                date_picker.timepicker();
            }
        });
        return true;
    });
    $('form.as_form, form.inplace_form').live('as:form_unloaded', function (event) {
        var as_form = $(this).closest("form");
        as_form.find('input.datetime_picker').each(function (index) {
            var date_picker = $(this);
            if (typeof(date_picker.datetimepicker) == 'function') {
                date_picker.datetimepicker('destroy');
            }
        });

        as_form.find('input.date_picker').each(function (index) {
            var date_picker = $(this);
            if (typeof(date_picker.datepicker) == 'function') {
                date_picker.datepicker('destroy');
            }
        });

        as_form.find('input.time_picker').each(function (index) {
            var date_picker = $(this);
            if (typeof(date_picker.timepicker) == 'function') {
                date_picker.timepicker('destroy');
            }
        });
        return true;
    });
});

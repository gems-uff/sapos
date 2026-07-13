$(document).ready(function() {
  function addAdvisementNotice() {
    var $form = $('.advisements-view .as_form.create');
    var $formBody = $form.find('ol.form').first();
    var noticeHtml = '<div class="alert alert-info advisement-notice" style="margin: 10px 15px; padding: 10px; background-color: #d9edf7; border: 1px solid #bce8f1; border-radius: 4px; color: #31708f;">' +
      '<i class="fa fa-info-circle"></i> ' +
      'Ao adicionar múltiplas orientações, dê preferência para a tela de matrículas' +
      '</div>';
    if ($formBody.length > 0 && $form.find('.advisement-notice').length === 0) {
      $formBody.before(noticeHtml);
    }
  }

  $(document).on('ajax:complete', '.advisements-view a.new', function() {
    setTimeout(addAdvisementNotice, 100);
  });

  $(document).ajaxComplete(function(event, xhr, settings) {
    if (settings.url && settings.url.indexOf('advisements') !== -1) {
      setTimeout(addAdvisementNotice, 100);
    }
  });
});

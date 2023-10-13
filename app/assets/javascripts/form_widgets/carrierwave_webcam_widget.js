function carrierwave_webcam(div) {
  let id = $(div).data("id");
  let url = $(div).data("url");
  let basename = $(div).data("basename");
  let column = $(div).data("column");
  let remove_label = $(div).data("remove-label");
  let input_name = `${basename}[${column}]`;
  let alt_name =`${basename}[${column}_]`;
  let remove_name = `${basename}[remove_${column}]`

  var input = $(`#${id}`);
  if (!input.length) return;
  $(div).append(`
    <a href="#" id="${id}_togglewebcam"
      style="${url ? "display:none;": "display:block;"} margin: 3px 0;"
    > Webcam </a>
    <a href="#" id="${id}_togglefile"
      style="display:none; margin: 3px 0;"
    > Arquivo </a>
    <div style="display:none; margin-left: 2px;" id="${id}_camera_inputs">
      <input
        autocomplete="off" class="photo-input text-input"
        id="${id}_" name="${alt_name}[base64_contents]"
        type="hidden">
      <input
        autocomplete="off" class="photo-input text-input"
        id="${id}_filename" name="${alt_name}[filename]"
        type="hidden" value="camera.jpg">
      <div
        id="${id}_camera" style="width: 400px; height: 300px;"
      ></div>
      <div>
        <a href="#" id="${id}_takesnapshot" style="margin: 3px 0;">
          Tirar foto
        </a>
      </div>
      <div class="previewwebcamimage"></div>
    </div>
  `)

  var remove_photo = $(div).find(`input[name="${remove_name}"]`);
  if (remove_label) {
    remove_photo.next().text(remove_label)
  }
  carrierwave_preview(div, input, url);

  var togglewebcam = $(`#${id}_togglewebcam`);
  var togglefile = $(`#${id}_togglefile`);

  var camerainput_div = $(`#${id}_camera_inputs`);
  var camerainput = $(`#${id}_`);
  var camerainputname = $(`#${id}_filename`);

  var webcam = $(`#${id}_camera`);
  var takesnapshot_link = $(`#${id}_takesnapshot`);

  var init = false;
  var toggler = function(e){
    e.preventDefault();
    togglewebcam.toggle();
    togglefile.toggle();
    camerainput_div.toggle()
    input.toggle();
    if (webcam.is(":visible")) {
      if (!init) {
        Webcam.attach(webcam[0]);
        init = true;

        form = input.parents("form").parent().find(".as_cancel").on("click", function(){
          Webcam.reset();
        })
        form = input.parents("form").on("submit", function(){
          Webcam.reset();
        })
      }

      camerainput.attr('name', `${input_name}[base64_contents]`);
      camerainputname.attr('name', `${input_name}[filename]`);
      input.attr('name', alt_name);
    } else {
      if (init) {
        Webcam.reset();
        init = false;
      }

      camerainput.attr('name', `${alt_name}[base64_contents]`);
      camerainputname.attr('name', `${alt_name}[filename]`);
      input.attr('name', input_name);
    }
  }

  togglewebcam.on('click', toggler);
  togglefile.on('click', toggler);
  takesnapshot_link.on('click', function(e) {
    e.preventDefault();
    Webcam.snap(function (data_uri) {
      var preview = camerainput_div.find('.previewwebcamimage')
      preview.html([
        '<p>Visualização:</p><img class="thumb" src="', data_uri, '" title="photo"/>'
      ].join(''));
      var raw_image_data = data_uri.replace(/^data\:image\/\w+\;base64\,/, '');
      camerainput.val(raw_image_data);
      camerainputname.val((new Date().getTime()) + '.jpg');
      remove_photo.val('false');
    });
  });

  remove_photo.next().on('click', function(e) {
    togglewebcam.show();
  })
}
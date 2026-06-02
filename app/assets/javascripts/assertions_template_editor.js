// $(document).on('codemirror:initialized', function(e, taId){

//   function insertTextById(id, text){
    
//     var editor = (window.CodeMirrorEditors || {})[id];
//     if (editor) {
//       var doc = editor.getDoc();
//       var pos = doc.getCursor();
//       doc.replaceRange(text, pos);
//       editor.focus();
//       return;
//     }
//     var ta = document.getElementById(id);
//     if (!ta) return;
//     var start = ta.selectionStart || 0;
//     var end = ta.selectionEnd || 0;
//     ta.value = ta.value.substring(0, start) + text + ta.value.substring(end);
//     ta.focus();
//   }

//   console.log('CodeMirror initialized for textarea id:', taId);
//   var ta = document.getElementById(taId);
//   if (ta) {
//     var editor = taId.nextSibling.CodeMirror || taId.CodeMirror;
//     console.log('Texto do editor:', editor ? editor.getValue().slice(0, 200) : 'Editor não encontrado');
//     console.log('Textarea element found:', ta);
//     console.log('Data attributes:', ta.dataset);
//   } else {
//     console.warn('Textarea element not found for id:', taId);
//   }
//   var editor = (window.CodeMirrorEditors || {})[taId];
//   console.log('Editor instance:', editor);
//   // usar editor...
// });
//   // unico handler de clique (delegação)
// document.addEventListener('click', function(e) {
//   var t = e.target;
//   // exemplos de ícones/ações — apenas log (não interrompe)
//   // if (t && t.classList && (t.classList.contains('fa-pencil') || t.classList.contains('new') || t.classList.contains('fa-eye'))) {
//   //   initAllAssertionEditors();
//   //   console.log('ícone/ação clicado', t);
//   // }
//   // console.log('Click event: ', e.target);
//   var btn = t && t.closest && t.closest('.insert-attribute, .insert-record-attribute, .insert-loop, .insert-conditional');
//   if (!btn) return;

//   var toolbar = btn.closest('.assertion-template-toolbar_pai');
//   if (!toolbar) return;

//   var editorId = toolbar.dataset.editorId;
//   var columns = JSON.parse(toolbar.dataset.columns || '[]');
//   var uniqueColumns = JSON.parse(toolbar.dataset.uniqueColumns || '[]');

//   function insertTextById(id, text){
//     var editor = (window.CodeMirrorEditors || {})[id];
//     console.log('Inserindo texto: ' + text + ' no editorId: ' + id);
//     console.log('Editor encontrado: ' + !!editor);
//     console.log('window.CodeMirrorEditors:', window.CodeMirrorEditors);
//     if (editor) {
//       var doc = editor.getDoc();
//       var pos = doc.getCursor();
//       doc.replaceRange(text, pos);
//       editor.focus();
//       return;
//     }
//     var ta = document.getElementById(id);
//     if (!ta) return;
//     var start = ta.selectionStart || 0;
//     var end = ta.selectionEnd || 0;
//     ta.value = ta.value.substring(0, start) + text + ta.value.substring(end);
//     ta.focus();
//   }

//   if (btn.classList.contains('insert-attribute')) {
//     if (!uniqueColumns.length) return alert('Nenhuma coluna única disponível. Simule para popular os valores.');
//     var choice = prompt('Escolha coluna (únicas):\n' + uniqueColumns.join(', '), uniqueColumns[0]);
//     if (choice) insertTextById(editorId, '{{ ' + choice + ' }}');
//   } else if (btn.classList.contains('insert-record-attribute')) {
//     if (!columns.length) return alert('Nenhuma coluna disponível.');
//     var choice2 = prompt('Escolha coluna para record:\n' + columns.join(', '), columns[0] || '');
//     if (choice2) insertTextById(editorId, '{{ record.' + choice2 + ' }}');
//   } else if (btn.classList.contains('insert-loop')) {
//     var sample = '{% for record in records %}\\n  {{ record.' + (columns[0] || 'coluna') + ' }}\\n{% endfor %}\\n';
//     insertTextById(editorId, sample);
//   } else if (btn.classList.contains('insert-conditional')) {
//     var sample2 = '{% if records.size > 0 %}\\n  <!-- conteúdo -->\\n{% endif %}\\n';
//     insertTextById(editorId, sample2);
//   }
// });

function createCodeMirror(taId, codetype, lineWrapping, set_size_str){
  console.log('Entrando no createCodeMirror', 'taId:', taId, 'codetype:', codetype, 'lineWrapping:', lineWrapping, 'set_size_str:', set_size_str);
  var editor = CodeMirror.fromTextArea(document.getElementById(taId),
    {mode: codetype,
    indentWithTabs: true,
    smartIndent: true,
    lineNumbers: true,
    matchBrackets : true,
    autofocus: true,
    lineWrapping: lineWrapping,

    }
  );
  if (set_size_str) {
    editor.setSize(null, set_size_str);
  }
  return editor;
}


function createPDFCodeMirror(taId, codetype, lineWrapping, set_size_str, columns, unique_columns, roles){ 
  console.log('Criando CodeMirror para PDF', 'taId:', taId, 'codetype:', codetype, 'lineWrapping:', lineWrapping, 'set_size_str:', set_size_str, 'columns:', columns, 'unique_columns:', unique_columns, 'roles:', roles);
  var editor = createCodeMirror(taId, codetype, lineWrapping, set_size_str);
  window.CodeMirrorEditors = window.CodeMirrorEditors || {};
  window.CodeMirrorEditors[taId] = editor;
  // console.log('Editor created for textarea id:', taId, 'with mode:', codetype, 'lineWrapping:', lineWrapping, 'setSize:', set_size_str, editor);
  // depois de inicializar o editor
  // console.log('CodeMirror initialized for textarea id:', taId);
  // adicionar barra de ferramentas com Bold / Italic
  try {
    if (editor && typeof editor.getWrapperElement === 'function') {
      // cria botão helper
      function _makeToolbarButton(html, title, onClick) {
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'cm-toolbar-btn';
        btn.title = title || '';
        btn.innerHTML = html;
        btn.style.marginRight = '6px';
        btn.addEventListener('click', function(ev){ ev.preventDefault(); onClick && onClick(ev); });
        return btn;
      }

      function _toggleWrapSelection(ed, wrapper) {
        var doc = ed.getDoc();
        var sel = doc.getSelection();
        if (!sel) {
          var pos = doc.getCursor();
          doc.replaceRange(wrapper + wrapper, pos);
          // move cursor between wrappers
          doc.setCursor({ line: pos.line, ch: pos.ch + wrapper.length });
          ed.focus();
          return;
        }
        var starts = sel.slice(0, wrapper.length) === wrapper;
        var ends = sel.slice(-wrapper.length) === wrapper;
        if (starts && ends) {
          doc.replaceSelection(sel.slice(wrapper.length, sel.length - wrapper.length));
        } else {
          doc.replaceSelection(wrapper + sel + wrapper);
        }
        ed.focus();
      }

      function _removeOptionsMenu() {
        if (window._cmOptionsMenu) {
          window._cmOptionsMenu.remove();
          window._cmOptionsMenu = null;
          document.removeEventListener('click', window._cmOptionsMenuDocHandler);
          document.removeEventListener('keydown', window._cmOptionsMenuKeyHandler);
          window._cmOptionsMenuDocHandler = null;
          window._cmOptionsMenuKeyHandler = null;
        }
      }

      function _showOptionsMenu(ed, anchorEl, options, formatFn) {
        _removeOptionsMenu();
        if (!options || !options.length) return alert('Nenhuma opção disponível.');
        var menu = document.createElement('div');
        menu.className = 'cm-options-menu';
        menu.style.position = 'absolute';
        menu.style.zIndex = 9999;
        menu.style.background = '#fff';
        menu.style.border = '1px solid #ccc';
        menu.style.borderRadius = '4px';
        menu.style.boxShadow = '0 2px 6px rgba(0,0,0,0.15)';
        menu.style.padding = '4px 0';
        menu.style.minWidth = '160px';
        var ul = document.createElement('ul');
        ul.style.listStyle = 'none';
        ul.style.margin = '0';
        ul.style.padding = '0';
        options.forEach(function(opt){
        var li = document.createElement('li');
        li.textContent = String(opt);
        li.style.padding = '6px 10px';
        li.style.cursor = 'pointer';
        li.addEventListener('mouseenter', function(){ li.style.background = '#f5f5f5'; });
        li.addEventListener('mouseleave', function(){ li.style.background = 'transparent'; });
        li.addEventListener('click', function(ev){
        ev.stopPropagation();
        var choice = opt;
        var doc = ed.getDoc();
        var pos = doc.getCursor();
        var text = (typeof formatFn === 'function') ? formatFn(choice) : ('{{' + choice + '}}');
        doc.replaceRange(text, pos);
        ed.focus();
        _removeOptionsMenu();
        });
        ul.appendChild(li);
        });
        menu.appendChild(ul);
        document.body.appendChild(menu);
        // posiciona o menu ancorado ao botão
        var rect = anchorEl.getBoundingClientRect();
        var top = rect.bottom + window.scrollY + 6;
        var left = rect.left + window.scrollX;
        // ajustar se sair da tela
        var menuRect = menu.getBoundingClientRect();
        if (left + menuRect.width > window.innerWidth) left = window.innerWidth - menuRect.width - 8;
        menu.style.top = top + 'px';
        menu.style.left = left + 'px';
        window._cmOptionsMenu = menu;
        window._cmOptionsMenuDocHandler = function(e){
        if (!menu.contains(e.target) && e.target !== anchorEl) _removeOptionsMenu();
        };
        window._cmOptionsMenuKeyHandler = function(e){
        if (e.key === 'Escape') _removeOptionsMenu();
        };
        // fechar ao clicar fora / esc
        setTimeout(function(){ // delay para evitar fechar no click que abriu
        document.addEventListener('click', window._cmOptionsMenuDocHandler);
        document.addEventListener('keydown', window._cmOptionsMenuKeyHandler);
        }, 0);
      }

      function _print_options(ed, options) {
        var optsStr = Array.isArray(options) ? options.join(', ') : String(options);
        console.log('Editor options: ' + optsStr);
        var choice = prompt('Escolha uma opção:\n' + optsStr, options[0]);
        // var choice = 'cursor'; // para teste, sempre insere "cursor"
        var doc = ed.getDoc();
        var pos = doc.getCursor();
        doc.replaceRange("{{" + choice + "}}", pos);
        ed.focus();
      }

      function _createToolbar(ed) {
        var wrapperEl = ed.getWrapperElement();
        if (!wrapperEl || !wrapperEl.parentNode) return;
        var toolbar = document.createElement('div');
        toolbar.className = 'codemirror-toolbar';
        toolbar.style.marginBottom = '6px';
        // Bold
        var b = _makeToolbarButton('<b>Bold</b>', 'Bold (wrap selection with **)', function(){ _toggleWrapSelection(ed, '**'); });
        // Italic
        var i = _makeToolbarButton('<i>Italic</i>', 'Italic (wrap selection with *)', function(){ _toggleWrapSelection(ed, '*'); });
        // colunas únicas
        var insertAttrBtn = _makeToolbarButton('Coluna', 'Insert attribute {{ coluna }}', function(ev){
          _showOptionsMenu(ed, ev.currentTarget, unique_columns, function(choice){ return '{{ ' + choice + ' }}'; });
          });
        // colunas de record
        var insertRecordAttrBtn = _makeToolbarButton('Record', 'Insert record attribute {{ record.coluna }}', function(ev){
          _showOptionsMenu(ed, ev.currentTarget, columns, function(choice){ return '{{ record.' + choice + ' }}'; });
          });
        // Loop
        var insertLoopBtn = _makeToolbarButton('Loop', 'Insert loop {% for record in records %}', function(ev){
          var doc = ed.getDoc();
          var pos = doc.getCursor();
          var sample = '{% for record in records %}{% endfor %}';
          doc.replaceRange(sample, pos);
          doc.setCursor({ line: pos.line, ch: pos.ch + 27 }); // posiciona dentro do loop
          ed.focus();
        });
        // Tags de linguagem
        var insertEnBtn = _makeToolbarButton('Linguagem En', 'Tags (Language en)', function(ev){
          var doc = ed.getDoc();
          var pos = doc.getCursor();
          var sample = '{% language en %}{% endlanguage %}';
          doc.replaceRange(sample, pos);
          doc.setCursor({ line: pos.line, ch: pos.ch + 17 }); // posiciona dentro do if
          ed.focus();
        });
        // Tags de data
        var insertDateBtn = _makeToolbarButton('Data', 'Insert date tag', function(ev){
          var dateOptions = ['default', 'defaultdate', 'shortdate', 'longdate', 'day', 'monthyear2', 'short', 'long', 'picker', 'monthyear'];
          _showOptionsMenu(ed, ev.currentTarget, dateOptions, function(choice){
          return '{{ data | localize: \''+choice+'\' }}';});
        });
        // Tags de email
        var insertEmailBtn = _makeToolbarButton('Email', 'Insert email tag', function(ev){
          _showOptionsMenu(ed, ev.currentTarget, roles, function(choice){
          return '\n{% emails ' + choice + ' %}\n';});
        });
        
        toolbar.appendChild(b);
        toolbar.appendChild(i);
        toolbar.appendChild(insertAttrBtn);
        toolbar.appendChild(insertLoopBtn);
        toolbar.appendChild(insertRecordAttrBtn);
        toolbar.appendChild(insertEnBtn);
        toolbar.appendChild(insertDateBtn);
        toolbar.appendChild(insertEmailBtn);
        wrapperEl.parentNode.insertBefore(toolbar, wrapperEl);
      }

      _createToolbar(editor);
    }
  } catch (e) { console.error('toolbar create error', e); }
  // if (window.jQuery) $(document).trigger('codemirror:initialized', [taId]);
  // else document.dispatchEvent(new CustomEvent('codemirror:initialized', { detail: { id: taId } }));
}
// })();

// rake assets:precompile
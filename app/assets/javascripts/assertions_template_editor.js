class CodeMIrrorToolbar {
  constructor(editor) {
    this.editor = editor;
    this.buttons = [];
    // this._createToolbar();
  }

  addButton(html, title, onClick) {
    // console.log('Adding button:', html, 'with title:', title);
    this.buttons.push(this._makeToolbarButton(html, title, onClick));
  }

  addWrapButton(html, title, wrapper_0, wrapper_1) {
    // console.log('Adding wrap button:', html, 'with wrappers:', wrapper_0, wrapper_1);
    this.buttons.push(this._makeToolbarButton(html, title, () => { this._toggleWrapSelection(wrapper_0, wrapper_1); }));
  }

  addChoiceButton(html, title, options, formatFn) {
    // console.log('Adding choice button:', html, 'with options:', options);
    this.buttons.push(this._makeToolbarButton(html, title, (ev) => {
      this._showOptionsMenu(ev.currentTarget, options, formatFn);
    }));
  }

  createToolbar() {
    var wrapperEl = this.editor.getWrapperElement();
    if (!wrapperEl || !wrapperEl.parentNode) return;
    var toolbar = document.createElement('div');
    toolbar.className = 'codemirror-toolbar';
    toolbar.style.marginBottom = '6px';
    this.buttons.forEach(function(btn){ toolbar.appendChild(btn); });
    wrapperEl.parentNode.insertBefore(toolbar, wrapperEl);
  }

  _makeToolbarButton(html, title, onClick) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'cm-toolbar-btn';
    btn.title = title || '';
    btn.innerHTML = html;
    btn.style.marginRight = '6px';
    btn.addEventListener('click', (ev) => { ev.preventDefault(); onClick && onClick(ev); });
    return btn;
  }

  _toggleWrapSelection(wrapper_0, wrapper_1) {
    var doc = this.editor.getDoc();
    var sel = doc.getSelection();
    if (!sel) {
      var pos = doc.getCursor();
      doc.replaceRange(wrapper_0 + wrapper_1, pos);
      // move cursor between wrappers
      doc.setCursor({ line: pos.line, ch: pos.ch + wrapper_0.length });
      this.editor.focus();
      return;
    }
    var starts = sel.slice(0, wrapper_0.length) === wrapper_0;
    var ends = sel.slice(-wrapper_1.length) === wrapper_1;
    if (starts && ends) {
      doc.replaceSelection(sel.slice(wrapper_0.length, sel.length - wrapper_1.length));
    } else {
      doc.replaceSelection(wrapper_0 + sel + wrapper_1);
    }
    this.editor.focus();
  }

  _ensureCmOptionsCSS() {
    if (document.getElementById('cm-options-menu-style')) return;
    var s = document.createElement('style');
    s.id = 'cm-options-menu-style';
    s.textContent = ''
      + '.cm-options-menu{position:absolute;z-index:9999;background:#fff;border:1px solid #ccc;border-radius:4px;box-shadow:0 2px 6px rgba(0,0,0,.15);padding:4px 0;min-width:160px;}'
      + '.cm-options-menu ul{list-style:none;margin:0;padding:0;}'
      + '.cm-options-menu li{padding:6px 10px;cursor:pointer;}'
      + '.cm-options-menu li:hover{background:#f5f5f5;}';
    document.head.appendChild(s);
  }

  _showOptionsMenu(anchorEl, options, formatFn) {
    this._ensureCmOptionsCSS();
    this._removeOptionsMenu();
    if (!options || !options.length) return console.warn('Nenhuma opção disponível.');

    // cria menu sem redeclarar estilos inline
    var self = this;
    var menu = document.createElement('div');
    menu.className = 'cm-options-menu';
    var ul = document.createElement('ul');

    options.forEach(function(opt){
      var li = document.createElement('li');
      li.textContent = String(opt);
      li.addEventListener('click', function(ev){
        ev.stopPropagation();
        var text = (typeof formatFn === 'function') ? String(formatFn(opt)) : ('{{' + opt + '}}');
        var doc = self.editor.getDoc();
        doc.replaceRange(text, doc.getCursor());
        self.editor.focus();
        self._removeOptionsMenu();
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
      if (!menu.contains(e.target) && e.target !== anchorEl) self._removeOptionsMenu();
    };
    window._cmOptionsMenuKeyHandler = function(e){
      if (e.key === 'Escape') self._removeOptionsMenu();
    };
    // fechar ao clicar fora / esc
    setTimeout(function(){ // delay para evitar fechar no click que abriu
      document.addEventListener('click', window._cmOptionsMenuDocHandler);
      document.addEventListener('keydown', window._cmOptionsMenuKeyHandler);
    }, 0);
  }

  _removeOptionsMenu() {
    if (window._cmOptionsMenu) {
      // console.log('Removing existing options menu');
      window._cmOptionsMenu.remove();
      window._cmOptionsMenu = null;
      document.removeEventListener('click', window._cmOptionsMenuDocHandler);
      document.removeEventListener('keydown', window._cmOptionsMenuKeyHandler);
      window._cmOptionsMenuDocHandler = null;
      window._cmOptionsMenuKeyHandler = null;
    }
  }
}

// function _createCodeMirror_toggleWrapSelection(ed, wrapper) {
//   var doc = ed.getDoc();
//   var sel = doc.getSelection();
//   if (!sel) {
//     var pos = doc.getCursor();
//     doc.replaceRange(wrapper + wrapper, pos);
//     // move cursor between wrappers
//     doc.setCursor({ line: pos.line, ch: pos.ch + wrapper.length });
//     ed.focus();
//     return;
//   }
//   var starts = sel.slice(0, wrapper.length) === wrapper;
//   var ends = sel.slice(-wrapper.length) === wrapper;
//   if (starts && ends) {
//     doc.replaceSelection(sel.slice(wrapper.length, sel.length - wrapper.length));
//   } else {
//     doc.replaceSelection(wrapper + sel + wrapper);
//   }
//   ed.focus();
// }

// function _createCodeMirror_removeOptionsMenu() {
//   if (window._cmOptionsMenu) {
//     console.log('Removing existing options menu');
//     window._cmOptionsMenu.remove();
//     window._cmOptionsMenu = null;
//     document.removeEventListener('click', window._cmOptionsMenuDocHandler);
//     document.removeEventListener('keydown', window._cmOptionsMenuKeyHandler);
//     window._cmOptionsMenuDocHandler = null;
//     window._cmOptionsMenuKeyHandler = null;
//   }
// }

// function _createCodeMirror_showOptionsMenu(ed, anchorEl, options, formatFn) {
//   _createCodeMirror_removeOptionsMenu();
//   if (!options || !options.length) return alert('Nenhuma opção disponível.');
//   // comeca criacao escolhas
//   var menu = document.createElement('div');
//   menu.className = 'cm-options-menu';
//   menu.style.position = 'absolute';
//   menu.style.zIndex = 9999;
//   menu.style.background = '#fff';
//   menu.style.border = '1px solid #ccc';
//   menu.style.borderRadius = '4px';
//   menu.style.boxShadow = '0 2px 6px rgba(0,0,0,0.15)';
//   menu.style.padding = '4px 0';
//   menu.style.minWidth = '160px';
//   var ul = document.createElement('ul');
//   ul.style.listStyle = 'none';
//   ul.style.margin = '0';
//   ul.style.padding = '0';
//   options.forEach(function(opt){
//     var li = document.createElement('li');
//     li.textContent = String(opt);
//     li.style.padding = '6px 10px';
//     li.style.cursor = 'pointer';
//     li.addEventListener('mouseenter', function(){ li.style.background = '#f5f5f5'; });
//     li.addEventListener('mouseleave', function(){ li.style.background = 'transparent'; });
//     li.addEventListener('click', function(ev){
//       ev.stopPropagation();
//       var choice = opt;
//       var doc = ed.getDoc();
//       var pos = doc.getCursor();
//       var text = (typeof formatFn === 'function') ? formatFn(choice) : ('{{' + choice + '}}');
//       doc.replaceRange(text, pos);
//       ed.focus();
//       _createCodeMirror_removeOptionsMenu();
//     });
//     ul.appendChild(li);
//   });
//   menu.appendChild(ul);
//   document.body.appendChild(menu);
//   // posiciona o menu ancorado ao botão
//   var rect = anchorEl.getBoundingClientRect();
//   var top = rect.bottom + window.scrollY + 6;
//   var left = rect.left + window.scrollX;
//   // ajustar se sair da tela
//   var menuRect = menu.getBoundingClientRect();
//   if (left + menuRect.width > window.innerWidth) left = window.innerWidth - menuRect.width - 8;
//   menu.style.top = top + 'px';
//   menu.style.left = left + 'px';
//   window._cmOptionsMenu = menu;
//   window._cmOptionsMenuDocHandler = function(e){
//     if (!menu.contains(e.target) && e.target !== anchorEl) _createCodeMirror_removeOptionsMenu();
//   };
//   window._cmOptionsMenuKeyHandler = function(e){
//     if (e.key === 'Escape') _createCodeMirror_removeOptionsMenu();
//   };
//   // fechar ao clicar fora / esc
//   setTimeout(function(){ // delay para evitar fechar no click que abriu
//     document.addEventListener('click', window._cmOptionsMenuDocHandler);
//     document.addEventListener('keydown', window._cmOptionsMenuKeyHandler);
//   }, 0);
// }
// function _makeToolbarButton(html, title, onClick) {
//   var btn = document.createElement('button');
//   btn.type = 'button';
//   btn.className = 'cm-toolbar-btn';
//   btn.title = title || '';
//   btn.innerHTML = html;
//   btn.style.marginRight = '6px';
//   btn.addEventListener('click', function(ev){ ev.preventDefault(); onClick && onClick(ev); });
//   return btn;
// }

function createCodeMirror(taId, codetype, lineWrapping, set_size_str){
  // console.log('Entrando no createCodeMirror', 'taId:', taId, 'codetype:', codetype, 'lineWrapping:', lineWrapping, 'set_size_str:', set_size_str);
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


function createPDFCodeMirror(taId, codetype, lineWrapping, set_size_str, columns, unique_columns, roles, formats){ 
  // console.log('Criando CodeMirror para PDF', 'taId:', taId, 'codetype:', codetype, 'lineWrapping:', lineWrapping, 'set_size_str:', set_size_str, 'columns:', columns, 'unique_columns:', unique_columns, 'roles:', roles);
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
      const toolbar = new CodeMIrrorToolbar(editor);
      toolbar.addWrapButton('<b>Bold</b>', 'Bold (wrap selection with **)', '**', '**');
      toolbar.addWrapButton('<i>Italic</i>', 'Italic (wrap selection with *)', '*', '*');
      toolbar.addChoiceButton('Coluna', 'Insert attribute {{ coluna }}', unique_columns, function(choice){ return '{{ ' + choice + ' }}'; });
      toolbar.addChoiceButton('Record', 'Insert record attribute {{ record.coluna }}', columns, function(choice){ return '{{ record.' + choice + ' }}'; });
      toolbar.addWrapButton('Loop', 'Insert loop {% for record in records %}', '{% for record in records %}', '{% endfor %}');
      toolbar.addWrapButton('Linguagem En', 'Tags (Language en)', '{% language en %}', '{% endlanguage %}');
      var keys = Object.keys(formats);
      formatsOptions = [];
      keys.forEach(function(key) { formatsOptions.push(key + ' => ' + formats[key]); });
      toolbar.addChoiceButton('Data', 'Insert date tag', formatsOptions, function(choice){
        return ' | localize: \''+choice.split(' => ')[0]+'\' ';
      });
      toolbar.addChoiceButton('Email', 'Insert email tag', roles, function(choice){
        return '\n{% emails ' + choice + ' %}\n';
      });
      toolbar.createToolbar();

      // function _toggleWrapSelection(ed, wrapper) {
      //   var doc = ed.getDoc();
      //   var sel = doc.getSelection();
      //   if (!sel) {
      //     var pos = doc.getCursor();
      //     doc.replaceRange(wrapper + wrapper, pos);
      //     // move cursor between wrappers
      //     doc.setCursor({ line: pos.line, ch: pos.ch + wrapper.length });
      //     ed.focus();
      //     return;
      //   }
      //   var starts = sel.slice(0, wrapper.length) === wrapper;
      //   var ends = sel.slice(-wrapper.length) === wrapper;
      //   if (starts && ends) {
      //     doc.replaceSelection(sel.slice(wrapper.length, sel.length - wrapper.length));
      //   } else {
      //     doc.replaceSelection(wrapper + sel + wrapper);
      //   }
      //   ed.focus();
      // }

      // function _removeOptionsMenu() {
      //   if (window._cmOptionsMenu) {
      //     window._cmOptionsMenu.remove();
      //     window._cmOptionsMenu = null;
      //     document.removeEventListener('click', window._cmOptionsMenuDocHandler);
      //     document.removeEventListener('keydown', window._cmOptionsMenuKeyHandler);
      //     window._cmOptionsMenuDocHandler = null;
      //     window._cmOptionsMenuKeyHandler = null;
      //   }
      // }

      // function _showOptionsMenu(ed, anchorEl, options, formatFn) {
      //   _removeOptionsMenu();
      //   if (!options || !options.length) return alert('Nenhuma opção disponível.');
      //   var menu = document.createElement('div');
      //   menu.className = 'cm-options-menu';
      //   menu.style.position = 'absolute';
      //   menu.style.zIndex = 9999;
      //   menu.style.background = '#fff';
      //   menu.style.border = '1px solid #ccc';
      //   menu.style.borderRadius = '4px';
      //   menu.style.boxShadow = '0 2px 6px rgba(0,0,0,0.15)';
      //   menu.style.padding = '4px 0';
      //   menu.style.minWidth = '160px';
      //   var ul = document.createElement('ul');
      //   ul.style.listStyle = 'none';
      //   ul.style.margin = '0';
      //   ul.style.padding = '0';
      //   options.forEach(function(opt){
      //   var li = document.createElement('li');
      //   li.textContent = String(opt);
      //   li.style.padding = '6px 10px';
      //   li.style.cursor = 'pointer';
      //   li.addEventListener('mouseenter', function(){ li.style.background = '#f5f5f5'; });
      //   li.addEventListener('mouseleave', function(){ li.style.background = 'transparent'; });
      //   li.addEventListener('click', function(ev){
      //   ev.stopPropagation();
      //   var choice = opt;
      //   var doc = ed.getDoc();
      //   var pos = doc.getCursor();
      //   var text = (typeof formatFn === 'function') ? formatFn(choice) : ('{{' + choice + '}}');
      //   doc.replaceRange(text, pos);
      //   ed.focus();
      //   _removeOptionsMenu();
      //   });
      //   ul.appendChild(li);
      //   });
      //   menu.appendChild(ul);
      //   document.body.appendChild(menu);
      //   // posiciona o menu ancorado ao botão
      //   var rect = anchorEl.getBoundingClientRect();
      //   var top = rect.bottom + window.scrollY + 6;
      //   var left = rect.left + window.scrollX;
      //   // ajustar se sair da tela
      //   var menuRect = menu.getBoundingClientRect();
      //   if (left + menuRect.width > window.innerWidth) left = window.innerWidth - menuRect.width - 8;
      //   menu.style.top = top + 'px';
      //   menu.style.left = left + 'px';
      //   window._cmOptionsMenu = menu;
      //   window._cmOptionsMenuDocHandler = function(e){
      //   if (!menu.contains(e.target) && e.target !== anchorEl) _removeOptionsMenu();
      //   };
      //   window._cmOptionsMenuKeyHandler = function(e){
      //   if (e.key === 'Escape') _removeOptionsMenu();
      //   };
      //   // fechar ao clicar fora / esc
      //   setTimeout(function(){ // delay para evitar fechar no click que abriu
      //   document.addEventListener('click', window._cmOptionsMenuDocHandler);
      //   document.addEventListener('keydown', window._cmOptionsMenuKeyHandler);
      //   }, 0);
      // }

      // function _print_options(ed, options) {
      //   var optsStr = Array.isArray(options) ? options.join(', ') : String(options);
      //   console.log('Editor options: ' + optsStr);
      //   var choice = prompt('Escolha uma opção:\n' + optsStr, options[0]);
      //   // var choice = 'cursor'; // para teste, sempre insere "cursor"
      //   var doc = ed.getDoc();
      //   var pos = doc.getCursor();
      //   doc.replaceRange("{{" + choice + "}}", pos);
      //   ed.focus();
      // }

      function _createToolbar(ed) {
        var wrapperEl = ed.getWrapperElement();
        if (!wrapperEl || !wrapperEl.parentNode) return;
        var toolbar = document.createElement('div');
        toolbar.className = 'codemirror-toolbar';
        toolbar.style.marginBottom = '6px';
        // Bold
        var b = _makeToolbarButton('<b>Bold</b>', 'Bold (wrap selection with **)', function(){ _createCodeMirror_toggleWrapSelection(ed, '**'); });
        // Italic
        var i = _makeToolbarButton('<i>Italic</i>', 'Italic (wrap selection with *)', function(){ _createCodeMirror_toggleWrapSelection(ed, '*'); });
        // colunas únicas
        var insertAttrBtn = _makeToolbarButton('Coluna', 'Insert attribute {{ coluna }}', function(ev){
          _createCodeMirror_showOptionsMenu(ed, ev.currentTarget, unique_columns, function(choice){ return '{{ ' + choice + ' }}'; });
          });
        // colunas de record
        var insertRecordAttrBtn = _makeToolbarButton('Record', 'Insert record attribute {{ record.coluna }}', function(ev){
          _createCodeMirror_showOptionsMenu(ed, ev.currentTarget, columns, function(choice){ return '{{ record.' + choice + ' }}'; });
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
          _createCodeMirror_showOptionsMenu(ed, ev.currentTarget, dateOptions, function(choice){
          return ' | localize: \''+choice+'\' ';});
        });
        // Tags de email
        var insertEmailBtn = _makeToolbarButton('Email', 'Insert email tag', function(ev){
          _createCodeMirror_showOptionsMenu(ed, ev.currentTarget, roles, function(choice){
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

      // _createToolbar(editor);
    }
  } catch (e) { console.error('toolbar create error', e); }
  // if (window.jQuery) $(document).trigger('codemirror:initialized', [taId]);
  // else document.dispatchEvent(new CustomEvent('codemirror:initialized', { detail: { id: taId } }));
}
// })();

// rake assets:precompile
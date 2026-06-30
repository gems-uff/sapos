class CodeMIrrorToolbar {
  constructor(editor) {
    this.editor = editor;
    this.buttons = [];
  }

  addButton(html, title, onClick) {
    this.buttons.push(this._makeToolbarButton(html, title, onClick));
  }

  addWrapButton(html, title, wrapper_0, wrapper_1) {
    this.buttons.push(this._makeToolbarButton(html, title, () => {
      this._toggleWrapSelection(wrapper_0, wrapper_1); 
    }));
  }

  addChoiceButton(html, title, options, formatFn) {
    this.buttons.push(this._makeToolbarButton(html, title, (ev) => {
      this._showOptionsMenu(ev.currentTarget, options, this._choiceOptionsMenu.bind(this),formatFn);
    }));
  }

  addChoiceWrapButton(html, title, options, wrapperFn) {
    this.buttons.push(this._makeToolbarButton(html, title, (ev) => {
      this._showOptionsMenu(ev.currentTarget, options, this._choiceWrapOptionsMenu.bind(this), wrapperFn);
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

  _choiceOptionsMenu(formatFn, opt) {
    var self = this;
    var text = (typeof formatFn === 'function') ? String(formatFn(opt)) : ('{{' + opt + '}}');
    var doc = self.editor.getDoc();
    doc.replaceRange(text, doc.getCursor());
    self.editor.focus();
  }

  _choiceWrapOptionsMenu(wrapperFn, opt) {
    var self = this;
    var wrapper1 = wrapperFn(opt)[0];
    var wrapper2 = wrapperFn(opt)[1];
    this._toggleWrapSelection(wrapper1, wrapper2);
  }


  _showOptionsMenu(anchorEl, options, callfn, formatFn) {
    this._ensureCmOptionsCSS();
    this._removeOptionsMenu();

    // cria menu sem redeclarar estilos inline
    var self = this;
    var menu = document.createElement('div');
    menu.className = 'cm-options-menu';
    var ul = document.createElement('ul');

    if (!options || options.length === 0) {
      var li = document.createElement('li');
      li.textContent = 'Nenhuma opção disponível';
      li.style.color = '#999';
      ul.appendChild(li);
    } else {
      options.forEach(function(opt){
        var li = document.createElement('li');
        li.textContent = String(opt);
        li.addEventListener('click', function(ev){
          ev.stopPropagation();
          callfn(formatFn, opt);
          self._removeOptionsMenu();
        });
        ul.appendChild(li);
      });
    }
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
      window._cmOptionsMenu.remove();
      window._cmOptionsMenu = null;
      document.removeEventListener('click', window._cmOptionsMenuDocHandler);
      document.removeEventListener('keydown', window._cmOptionsMenuKeyHandler);
      window._cmOptionsMenuDocHandler = null;
      window._cmOptionsMenuKeyHandler = null;
    }
  }

  icons = {
    bold: '<i class="fa fa-bold" aria-hidden="true"></i>',
    italic: '<i class="fa fa-italic" aria-hidden="true"></i>',
    align: '<i class="fa fa-align-justify" aria-hidden="true"></i>',
  }
}

function escapeRegExp(s){ return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

function replaceWithDict(list, dict){
  const keys = Object.keys(dict).sort((a,b) => b.length - a.length); // maior primeiro
  if (keys.length === 0) return list.slice();
  const re = new RegExp(keys.map(escapeRegExp).join('|'), 'g'); // sensível a maiúsculas
  return list.map(str => str.replace(re, match => dict[match]));
}

function listDateFormats(formats){
  parans = {
    '%A': 'segunda',
    '%B': 'julho',
    '%b': 'jul',
    '%m': '07',
    '%Y': '2011',
    '%H': '10',
    '%M': '02',
    '%S': '10',
    '%d': '18',
  }
  formatsOptions = [];
  Object.keys(formats).forEach(function(key){ formatsOptions.push(key + ' => ' + formats[key]); });
  return replaceWithDict(formatsOptions, parans)
}

function createCodeMirror(taId, codetype, lineWrapping, set_size_str){
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
  var editor = createCodeMirror(taId, codetype, lineWrapping, set_size_str);
  window.CodeMirrorEditors = window.CodeMirrorEditors || {};
  window.CodeMirrorEditors[taId] = editor;
  try {
    if (editor && typeof editor.getWrapperElement === 'function') {
      // cria botão helper
      const toolbar = new CodeMIrrorToolbar(editor);
      // formatação de texto
      toolbar.addWrapButton(toolbar.icons.bold, 'Negrito', '<b>', '</b>');
      toolbar.addWrapButton(toolbar.icons.italic, 'Itálico', '<i>', '</i>');
      toolbar.addChoiceWrapButton(toolbar.icons.align, 'Alinhamento', ['left', 'center', 'right', 'justify'], function(choice){
        return ['{% align ' + choice + ' %}\n','\n{% endalign %}'];
      });
      // variáveis e estruturas
      toolbar.addChoiceButton('Coluna', 'Variável {{ coluna }}', unique_columns, function(choice){ return '{{ ' + choice + ' }}'; });
      toolbar.addChoiceButton('Record', 'Variavel {{ record }}', columns, function(choice){ return '{{ record.' + choice + ' }}'; });
      toolbar.addWrapButton('Loop', 'Loop {% for record in records %}', '{% for record in records %}', '{% endfor %}');
      // Filtros
      toolbar.addChoiceButton('Data', 'Filtro de Data', listDateFormats(formats), function(choice){
        return ' | localize: \''+choice.split(' => ')[0]+'\' ';
      });
      // Tags
      toolbar.addWrapButton('Linguagem En', 'Tag (Language en)', '{% language en %}', '{% endlanguage %}');
      toolbar.addChoiceButton('Email', 'Tag de Email', roles, function(choice){
        return '\n{% emails ' + choice + ' %}\n';
      });
      // criar toolbar
      toolbar.createToolbar();
    }
  } catch (e) { console.error('toolbar create error', e); }
}

function createEmailCodeMirror(taId, codetype, lineWrapping, set_size_str, columns, unique_columns, roles, formats){ 
  var editor = createCodeMirror(taId, codetype, lineWrapping, set_size_str);
  window.CodeMirrorEditors = window.CodeMirrorEditors || {};
  window.CodeMirrorEditors[taId] = editor;
  try {
    if (editor && typeof editor.getWrapperElement === 'function') {
      // cria botão helper
      const toolbar = new CodeMIrrorToolbar(editor);
      // formatação de texto
      toolbar.addWrapButton(toolbar.icons.bold, 'Negrito', '<b>', '</b>');
      toolbar.addWrapButton(toolbar.icons.italic, 'Itálico', '<i>', '</i>');
      toolbar.addChoiceWrapButton(toolbar.icons.align, 'Alinhamento', ['left', 'center', 'right', 'justify'], function(choice){
        return ['{% align ' + choice + ' %}\n','\n{% endalign %}'];
      });
      // variáveis e estruturas
      toolbar.addChoiceButton('Coluna', 'Variável {{ coluna }}', unique_columns, function(choice){ return '{{ ' + choice + ' }}'; });
      toolbar.addChoiceButton('Record', 'Variavel {{ record }}', columns, function(choice){ return '{{ record.' + choice + ' }}'; });
      toolbar.addWrapButton('Loop', 'Loop {% for record in records %}', '{% for record in records %}', '{% endfor %}');
      // Filtros
      toolbar.addChoiceButton('Data', 'Filtro de Data', listDateFormats(formats), function(choice){
        return ' | localize: \''+choice.split(' => ')[0]+'\' ';
      });
      // Tags
      toolbar.addWrapButton('Linguagem En', 'Tag (Language en)', '{% language en %}', '{% endlanguage %}');
      toolbar.addChoiceButton('Email', 'Tag de Email', roles, function(choice){
        return '\n{% emails ' + choice + ' %}\n';
      });
      // criar toolbar
      toolbar.createToolbar();
    }
  } catch (e) { console.error('toolbar create error', e); }
}


// rake assets:precompile
if (typeof(Class) === 'undefined') {
  /* Simple Inheritance
   http://ejohn.org/blog/simple-javascript-inheritance/
  */
  (function(){
    var initializing = false, fnTest = /xyz/.test(function(){xyz;}) ? /\b_super\b/ : /.*/;
  
    // The base Class implementation (does nothing)
    this.Class = function(){};
   
    // Create a new Class that inherits from this class
    Class.extend = function(prop) {
      var _super = this.prototype;
     
      // Instantiate a base class (but only create the instance,
      // don't run the init constructor)
      initializing = true;
      var prototype = new this();
      initializing = false;
     
      // Copy the properties over onto the new prototype
      for (var name in prop) {
        // Check if we're overwriting an existing function
        prototype[name] = typeof prop[name] == "function" &&
          typeof _super[name] == "function" && fnTest.test(prop[name]) ?
          (function(name, fn){
            return function() {
              var tmp = this._super;
             
              // Add a new ._super() method that is the same method
              // but on the super-class
              this._super = _super[name];
             
              // The method only need to be bound temporarily, so we
              // remove it when we're done executing
              var ret = fn.apply(this, arguments);       
              this._super = tmp;
             
              return ret;
            };
          })(name, prop[name]) :
          prop[name];
      }
     
      // The dummy class constructor
      function Class() {
        // All construction is actually done in the init method
        if ( !initializing && this.init )
          this.init.apply(this, arguments);
      }
     
      // Populate our constructed prototype object
      Class.prototype = prototype;
     
      // Enforce the constructor to be what we expect
      Class.constructor = Class;
  
      // And make this class extendable
      Class.extend = arguments.callee;
     
      return Class;
    };
  })();
};

/*
 jQuery delayed observer
 (c) 2007 - Maxime Haineault (max@centdessin.com)
 
 Special thanks to Stephen Goguen & Tane Piper.
 
 Slight modifications by Elliot Winkler
*/

if (typeof(jQuery.fn.delayedObserver) === 'undefined') { 
  (function() {
    var delayedObserverStack = [];
    var observed;
   
    function delayedObserverCallback(stackPos) {
      observed = delayedObserverStack[stackPos];
      if (observed.timer) return;
     
      observed.timer = setTimeout(function(){
        observed.timer = null;
        observed.callback(observed.obj.val(), observed.obj);
      }, observed.delay * 1000);
  
      observed.oldVal = observed.obj.val();
    } 
    
    // going by
    // <http://www.cambiaresearch.com/c4/702b8cd1-e5b0-42e6-83ac-25f0306e3e25/Javascript-Char-Codes-Key-Codes.aspx>
    // I think these codes only work when using keyup or keydown
    function isNonPrintableKey(event) {
      var code = event.keyCode;
      return (
        event.metaKey ||
        (code >= 9 || code <= 16) || (code >= 27 && code <= 40) || (code >= 91 && code <= 93) || (code >= 112 && code <= 145)
      );
    }
   
    jQuery.fn.extend({
      delayedObserver:function(delay, callback){
        $this = $(this);
       
        delayedObserverStack.push({
          obj: $this, timer: null, delay: delay,
          oldVal: $this.val(), callback: callback
        });
         
        stackPos = delayedObserverStack.length-1;
       
        $this.keyup(function(event) {
          if (isNonPrintableKey(event)) return;
          observed = delayedObserverStack[stackPos];
            if (observed.obj.val() == observed.obj.oldVal) return;
            else delayedObserverCallback(stackPos);
        });
      }
    });
  })();
};

$(document).ready(function() {
  RecordSelect.document_loaded = true;
  $('div.record-select * li.record a').live('ajax:before', function(event) {
    var link = $(this);
    if (link) {
      if (RecordSelect.notify(link) == false) {
        return false;
      } else {
        link.toggleClass("selected");
      }
    }
    return true;
  });
});

/**
Form.Element.AfterActivity = function(element, callback, delay) {
  element = $(element);
  if (!delay) delay = 0.25;
  new Form.Element.Observer(element, delay, function(element, value) {
    // TODO: display loading indicator
    if (element.activity_timer) clearTimeout(element.activity_timer);
    element.activity_timer = setTimeout(function() {
      callback(element.value);
    }, delay * 1000 + 50);
  });
}
*/

var RecordSelect = new Object();
RecordSelect.document_loaded = false;

RecordSelect.notify = function(item) {
  var e = item.closest('.record-select-handler');
  var onselect = e.get(0).onselect || e.attr('onselect');
  if (typeof onselect != 'function') onselect = eval(onselect);
  if (onselect)
  {
    try {
      // .unescapeHTML() not implemented so far
      var label = $.trim(item.find('label').first().html());
      if (label.length == 0) {
        label = item.html();
      }
      onselect(item.parent().attr('id').substr(2), label, e);
    } catch(e) {
      alert(e);
    }
    return false;
  }
  else return true;
}

RecordSelect.render_page = function(record_select_id, page) {
  $('#' + record_select_id + ' ol').first().replaceWith(page);
};

RecordSelect.Abstract = Class.extend({
  /**
   * obj - the id or element that will anchor the recordselect to the page
   * url - the url to run the recordselect
   * options - ??? (check concrete classes)
   */
  init: function(obj, url, options) {
    if (typeof(obj) == 'string') obj = '#' + obj;
    this.obj = $(obj);
    this.url = url;
    this.options = options;
    this.container;
    if (this.options.onchange && typeof(this.options.onchange) != 'function') {
      this.options.onchange = eval(this.options.onchange);
    }

    if (RecordSelect.document_loaded) {
      this.onload();
    } else {
      var _this = this; $(document).ready(function() { _this.onload(); })
    }
  },

  /**
   * Finish the setup - IE doesn't like doing certain things before the page loads
   * --override--
   */
  onload: function() {},

  /**
   * the onselect event handler - when someone clicks on a record
   * --override--
   */
  onselect: function(id, value) {
    alert(id + ': ' + value);
  },

  /**
   * opens the recordselect
   */
  open: function() {
    if (this.is_open()) return;
    var _this = this;
    $.ajax({
      url: this.url,
      //type: "POST",
      //data: options['params'],
      //dataType: options.ajax_data_type,
      success: function(data){
        _this.container.html(data);
        _this.show();
        $(document.body).mousedown(jQuery.proxy(_this, "onbodyclick"));
      }
    });
  },

  /**
   * positions and reveals the recordselect
   */
  show: function() {
    var offset = this.obj.offset();
    this.container.css('left', offset.left)
                  .css('top', (this.obj.height() + offset.top));

    if (this._use_iframe_mask()) {
      this.container.after('<iframe src="javascript:false;" class="record-select-mask" />');
      var mask = this.container.next('iframe');
      mask.css('left', this.container.css('left'))
          .css('top', this.container.css('top'));
    }

    this.container.show();

    if (this._use_iframe_mask()) {
      var dimensions = this.container.children().first();
      mask.css('width', dimensions.css('width'))
          .css('height', dimensions.css('height'));
    }
  },

  /**
   * closes the recordselect by emptying the container
   */
  close: function() {
    if (this._use_iframe_mask()) {
      this.container.next('iframe').remove();
    }

    this.container.hide();
    // hopefully by using remove() instead of innerHTML we won't leak memory
    this.container.children().remove();
  },

  /**
   * returns true/false for whether the recordselect is open
   */
  is_open: function() {
	  return (!($.trim(this.container.html()).length == 0))
  },

  /**
   * when the user clicks outside the dropdown
   */
  onbodyclick: function(event) {
    if (!this.is_open()) return;
    if (this.container.has($(event.target)).length > 0) {
      return;
    } else {
      this.close();
    }
  },

  /**
   * creates and initializes (and returns) the recordselect container
   */
  create_container: function() {
    var e = $("<div />", {'class': "record-select-container record-select-handler"});
    e.css('display', 'none')
    $(document.body).append(e);
    e.get(0).onselect = $.proxy(this, "onselect")
    return e;
  },
  
  onkeyup: function(event) {
    if (!this.is_open()) return;
    this.container.find('.text-input').val(this.obj.val()).trigger(event);
  },

  /**
   * all the behavior to respond to a text field as a search box
   */
  _respond_to_text_field: function(text_field) {
    // attach the events to start this party
    text_field.focus($.proxy(this, 'open'));

    // the autosearch event - needs to happen slightly late (keyup is later than keypress)
    text_field.keyup($.proxy(this, 'onkeyup'));

    // keyboard navigation, if available
    if (this.onkeypress) {
      text_field.keypress($.proxy(this, "onkeypress"));
    }
  },

  _use_iframe_mask: function() {
    return this.container.insertAdjacentHTML ? true : false;
  }
});



/**
 * Adds keyboard navigation to RecordSelect objects
 */
$.extend(RecordSelect.Abstract.prototype, {
  current: null,

  /**
   * keyboard navigation - where to intercept the keys is up to the concrete class
   */
  onkeypress: function(ev) {
    var elem;
    switch (ev.keyCode) {
      case 38: //Event.KEY_UP
        if (this.current && this.current.closest('.record-select')) elem = this.current.prev();
        if (!elem) elem = this.container.find('ol li.record').last();
        this.highlight(elem);
        break;
      case 40: //Event.KEY_DOWN
        if (this.current && this.current.closest('.record-select')) elem = this.current.next();
        if (!elem) elem = this.container.find('ol li.record').first();
        this.highlight(elem);
        break;
      case 13: // Event.KEY_RETURN
        if (this.current) this.current.find('a').click();
        break;
      case 39: // Event.KEY_RIGHT
        elem = this.container.find('li.pagination.next');
        if (elem) elem.find('a').click();
        break;
      case 37: // Event.KEY_LEFT
        elem = this.container.find('li.pagination.previous');
        if (elem) elem.find('a').click();
        break;
      case 27: // Event.KEY_ESC
        this.close();
        break;
      default:
        return true;
    }
    ev.preventDefault(); // so "enter" doesn't submit the form, among other things(?)
  },

  /**
   * moves the highlight to a new object
   */
  highlight: function(obj) {
    if (this.current) this.current.removeClass('current');
    this.current = $(obj);
    obj.addClass('current');
  }
});

/**
 * Used by link_to_record_select
 * The options hash should contain a onselect: key, with a javascript function as value
 */
RecordSelect.Dialog = RecordSelect.Abstract.extend({
  onload: function() {
    this.container = this.create_container();
    this.obj.click($.proxy(this, "toggle"));
    if (this.onkeypress) this.obj.keypress($.proxy(this, 'onkeypress'));
  },

  onselect: function(id, value) {
    if (this.options.onselect(id, value) != false) this.close();
  },

  toggle: function() {
    if (this.is_open()) this.close();
    else this.open();
  }
});

/**
 * Used by record_select_field helper
 * The options hash may contain id: and label: keys, designating the current value
 * The options hash may also include an onchange: key, where the value is a javascript function (or eval-able string) for an callback routine.
 */
RecordSelect.Single = RecordSelect.Abstract.extend({
  onload: function() {
    // initialize the container
    this.container = this.create_container();
    this.container.addClass('record-select-autocomplete');

    // create the hidden input
    this.obj.after('<input type="hidden" name="" value="" />');
    this.hidden_input = this.obj.next();

    // transfer the input name from the text input to the hidden input
    this.hidden_input.attr('name', this.obj.attr('name'));
    this.obj.attr('name', '');

    // initialize the values
    this.set(this.options.id, this.options.label);

    this._respond_to_text_field(this.obj);
    if (this.obj.focused) this.open(); // if it was focused before we could attach observers
  },

  close: function() {
    // if they close the dialog with the text field empty, then delete the id value
    if (this.obj.val() == '') this.set('', '');

    RecordSelect.Abstract.prototype.close.call(this);
  },

  onselect: function(id, value) {
    this.set(id, value);
    if (this.options.onchange) this.options.onchange.call(this, id, value);
    this.close();
  },

  /**
   * sets the id/label
   */
  set: function(id, label) {
    // unescaped html missing for label
    this.obj.val(label); 
    this.hidden_input.val(id);
  }
});

/**
 * Used by record_multi_select_field helper.
 * Options:
 *   list - the id (or object) of the <ul> to contain the <li>s of selected entries
 *   current - an array of id:/label: keys designating the currently selected entries
 */
RecordSelect.Multiple = RecordSelect.Abstract.extend({
  onload: function() {
    // initialize the container
    this.container = this.create_container();
    this.container.addClass('record-select-autocomplete');

    // decide where the <li> entries should be placed
    if (this.options.list) this.list_container = $(this.options.list);
    else this.list_container = this.obj.next('ul');

    // take the input name from the text input, and store it for this.add()
    this.input_name = this.obj.attr('name');
    this.obj.attr('name', '');

    // initialize the list
    for(var i = 0, length = this.options.current.length; i < length; i++) {
      this.add(this.options.current[i].id, this.options.current[i].label); 
    }

    this._respond_to_text_field(this.obj);
    if (this.obj.focused) this.open(); // if it was focused before we could attach observers
  },

  onselect: function(id, value) {
    this.add(id, value);
  },

  /**
   * Adds a record to the selected list
   */
  add: function(id, label) {
    // return silently if this value has already been selected
    if (this.list_container.has('input[value=' + id + ']').length > 0) return;

    var entry = '<li>'
              + '<a href="#" onclick="$(this).parent().remove(); return false;" class="remove">remove</a>'
              + '<input type="hidden" name="' + this.input_name + '" value="' + id + '" />'
              + '<label>' + label + '</label>'
              + '</li>';
    this.list_container.prepend(entry)
  }
});

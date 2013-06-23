(function(root) {

  csssEditor = function(options, cb) {
    var self = this;
    // options or cb as argument(s)
    if (typeof options === 'function') {
      cb = options;
      options = {};
    }
    // set default options
    if (typeof options !== 'object' && options !== null) options = {};
    if (typeof options.debug    !== 'boolean') options.debug = false;
    if (typeof options.stash    !== 'boolean') options.stash = true;
    if (typeof options.selector !== 'object')  options.selector = $('body');
    if (typeof options.beautify !== 'boolean') options.beautify = true;
    this.$selector = options.selector;
    this.options = options;
    if (typeof cb === 'function') {
      self.ready = cb;
      self.load(function(err, arg){
        self.applyContainer();
        self.ready(err,arg);
      });
    }
  }

  csssEditor.prototype.error = null;
  csssEditor.prototype.done  = null;
  csssEditor.prototype.ready = null;

  csssEditor.prototype.csss = null;

  csssEditor.prototype.applyCssToDocument = function(css) {
      $('#AppliedCSS').remove();
      var reset = 'html * { '+CSSS.prototype.attributesTypes.split('|').join(': auto;\n')+' }';
      $('<style type="text/css" id="AppliedCSS">'+reset+'</style>').html(css).appendTo('head');
    }

  csssEditor.prototype.applyCSSSToDocument = function(input) {
    var self = this;
    try {
      csss = self.csss = new CSSS();
      csss.parse(input);
      var css = csss.css();
      self.applyCssToDocument(css);
      if (typeof self.done === 'function')
        self.done(null, css);
    } catch (e) {
      if (typeof self.error === 'function')
        self.error(e, csss.source);
      if (typeof self.done  === 'function')
        self.done(e, css);
      if (self.options.debug)
        console.error(e);
    }
  }
  
  csssEditor.prototype.applyContainer = function() {
    var css = "\
    #csssEditor_container { position: fixed; overflow: hidden; top: 0; right: 0; width: 20em; height: 100%; box-shadow: -2px 0 5px rgba(0,0,0,0.2); z-index: 100; }\
    #csssEditor_container.collapsed { width: 1em; }\
    #csssEditor_container.collapsed #csssEditor_input { color: transparent; }\
    #csssEditor_input { width: 100%; height: 100%; border: 1px solid #ccc; padding: 10px; font-family: 'Menlo', 'Consolas', Courier; }\
    #csssEditor_error { position: absolute; background: #ffa1a1; border-radius: 2px; color: #fff; opacity: 1; right: 0; bottom: 0px; font-size: 0.8em; width: 100%; text-align: center; } \
    #csssEditor_actions { position: absolute; bottom: 0px; right: 5px;} \
    #cssseditor_actions button { background: #ddd; color: #888; border: 1px solid #ccc; text-shadow: 1px 1px 0px #fff; padding: 2px 3px; border-radius: 2px; } \
    ";
    var html = '\
    <div id="csssEditor_container"> \
      <textarea id="csssEditor_input"></textarea> \
      <div id="csssEditor_actions"> \
        <button id="CSS2console">CSS2console</button> \
        <button id="CoffeeScript2console">CoffeeScript2console</button> \
      </div> \
      <div id="csssEditor_error">Error message</div> \
    </div> \
    <style type="text/css">'+css+'</style> \
    ';
    var self = this;
    self.$selector.prepend(html);
    $('#csssEditor_container').on('dblclick', function() { $(this).toggleClass('collapsed'); });
    if (self.options.stash) {
      // put stashed value into textarea
      var input = stash.get('csss_editor_input') || '';
      $('#csssEditor_input').text(input);
      self.applyCSSSToDocument(input);
    }
    $('#csssEditor_input').on('keyup', function(e){
      var input = $(this).val();
      if (self.options.stash)
        stash.set('csss_editor_input', input);
      self.applyCSSSToDocument(input);
    });
    $('#CSS2console').on('click', function(){
      var css = self.csss.css();
      css = cssbeautify(css, { indent: '  '});
      console.log(css);
    });
    $('#CoffeeScript2console').on('click', function(){
      console.log(self.csss.source);
    });
  }

  csssEditor.prototype.load = function(cb) {
    var self = this;
    var loadJS = function (url, loaded) {
      var scr = document.createElement('script');
      scr.type = 'text/javascript';
      scr.src = url;
      if (navigator.userAgent.indexOf('MSIE') > -1) {
        scr.onload = scr.onreadystatechange = function () {
          if (self.readyState == "loaded" || self.readyState == "complete") {
            if (loaded) { loaded(); }
          }
          scr.onload = scr.onreadystatechange = null;
        };
      } else {
        scr.onload = loaded;
      }
      document.getElementsByTagName('head')[0].appendChild(scr);
    };


    var files = {
      CoffeeScript: 'coffee-script.js',
      // StashJS: 'stash.min.js',
      CSSBeautify: 'cssbeautify.js',
      CSSS: 'csss.js'
    };

    var filesCount = 0;//Object.keys(files).length;

    var loaded = 0;

    var finished = function() {
      loaded++;
      if (loaded >= filesCount) {
        if (typeof $ === 'undefined') throw new Error('jQuery is needed');
        if (typeof cb === 'function')
          cb(null, self);
      }
    } 

    for (var name in files) {
      // don't load twice, it's alright    
      if ((name === 'CoffeeScript') && (typeof CoffeeScript !== 'undefined')) continue;
      if ((name === 'StashJS') && (typeof stash !== 'undefined')) continue;
      if ((name === 'CSSBeautify') && (typeof cssbeautify !== 'undefined')) continue;
      if ((name === 'CSSS') && (typeof CSSS !== 'undefined')) continue;
      filesCount++;
      loadJS(files[name].replace(/^http(s)*\:/, ''), finished);
    }
    
  }

})(window);
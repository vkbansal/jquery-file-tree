(function($, window, document) {
  var FileTree, Plugin, defaults, old;
  defaults = {
    data: [],
    animationSpeed: 400,
    folderTrigger: "click",
    hideFiles: false,
    fileContainer: null,
    nodeName: 'name',
    nodeTitle: 'name'
  };

  /*
  		FILETREE CLASS DEFINITION
   */
  FileTree = (function() {
    function FileTree(element, options) {
      this.element = element;
      this.settings = $.extend({}, defaults, options);
      this._defaults = defaults;
      this.init();
    }

    FileTree.prototype.init = function() {
      var data;
      data = this.settings.data;
      this._createTree.call(this, this.element, data);
      $(this.element).addClass('filetree');
      this._addListeners();
    };

    FileTree.prototype.open = function() {
      console.log(this.element);
    };

    FileTree.prototype._createTree = function(elem, data) {
      var $elem, a, arrow, file, item, key, li, ul, value, _files, _folders, _i, _j, _len, _len1, _subfolders;
      $elem = $(elem);
      _files = [];
      _folders = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        file = data[_i];
        if (file.type === 'folder') {
          _folders.push(file);
        }
        if (file.type === 'file') {
          _files.push(file);
        }
      }
      _files.sort(this._nameSort);
      _folders.sort(this._nameSort);
      data = _folders.concat(_files);
      if ($elem.prop('tagName').toLowerCase() === 'ul') {
        ul = $elem;
      } else {
        ul = $(document.createElement('ul'));
      }
      for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
        item = data[_j];
        li = $(document.createElement('li')).addClass(item.type);
        if (item.type === 'file' && this.settings.hideFiles === true) {
          li.addClass('hidden');
        }
        a = $(document.createElement('a')).attr('href', '#').attr('title', item[this.settings.nodeTitle]).html(item[this.settings.nodeName]);
        for (key in item) {
          value = item[key];
          if (item.hasOwnProperty(key) && key !== 'children') {
            a.data(key, value);
          }
        }
        li.append(a);
        ul.append(li);
        if (item.type === 'folder' && typeof item.children !== 'undefined' && item.children.length > 0) {
          li.addClass('collapsed').addClass('has-children');
          arrow = $(document.createElement('button')).addClass('arrow');
          li.prepend(arrow);
          if (this.settings.hideFiles === true) {
            _subfolders = $.grep(item.children, function(e) {
              return e.type === 'folder';
            });
            if (_subfolders.length > 0) {
              li.removeClass('collapsed').removeClass('has-children');
              li.find('button').removeClass('arrow').addClass('no-arrow');
            }
          }
          this._createTree.call(this, li, item.children);
        }
      }
      $elem.append(ul);
    };

    FileTree.prototype._openFolder = function(elem) {
      var $elem, ev_end, ev_start, that, ul;
      $elem = $(elem).parent('li');
      that = this;
      ev_start = $.Event('open.folder.filetree');
      ev_end = $.Event('opened.folder.filetree');
      ul = $elem.find('ul').eq(0);
      $elem.find('a').eq(0).trigger(ev_start);
      ul.slideDown(that.settings.animationSpeed, function() {
        $elem.removeClass('collapsed').addClass('expanded');
        ul.removeAttr('style');
        $elem.find('a').eq(0).trigger(ev_end);
      });
      return false;
    };

    FileTree.prototype._closeFolder = function(elem) {
      var $elem, ev_end, ev_start, that, ul;
      $elem = $(elem).parent('li');
      that = this;
      ev_start = $.Event('close.folder.filetree');
      ev_end = $.Event('closed.folder.filetree');
      ul = $elem.find('ul').eq(0);
      $elem.find('a').eq(0).trigger(ev_start);
      ul.slideUp(that.settings.animationSpeed, function() {
        $elem.removeClass('expanded').addClass('collapsed');
        ul.removeAttr('style');
        $elem.find('a').eq(0).trigger(ev_end);
      });
      return false;
    };

    FileTree.prototype._addListeners = function() {
      var $root, that;
      $root = $(this.element);
      that = this;
      $root.on('click', 'li.folder.collapsed.has-children > button.arrow', function(event) {
        return that._openFolder(this);
      });
      $root.on('click', 'li.folder.expanded.has-children > button.arrow', function(event) {
        return that._closeFolder(this);
      });
      $root.on('click', 'li.folder > a', function(event) {
        $(this).triggerHandler('click.folder.filetree');
        return event.stopImmediatePropagation();
      });
      $root.on('click', 'li.file > a', function(event) {
        $(this).triggerHandler('click.file.filtree');
        return event.stopImmediatePropagation();
      });
      $root.on('click', 'li.folder, li.file', function(event) {});
    };

    FileTree.prototype._nameSort = function(a, b) {
      if (a.name.toLowerCase() < b.name.toLowerCase()) {
        return -1;
      } else if (a.name.toLowerCase() > b.name.toLowerCase()) {
        return 1;
      } else {
        return 0;
      }
    };

    return FileTree;

  })();

  /*
  		PLUGIN DEFINITION
   */
  Plugin = function(options) {
    return this.each(function() {
      var $this, data;
      $this = $(this);
      data = $this.data('$.filetree');
      if (!data) {
        $this.data("$.filetree", (data = new FileTree(this, options)));
      }
      if (typeof options === 'string') {
        return data[options].call($this);
      }
    });
  };
  old = $.fn.filetree;
  $.fn.filetree = Plugin;
  $.fn.filetree.Constructor = FileTree;

  /*
  		NO CONFLICT
   */
  $.fn.filetree.noConflict = function() {
    $.fn.filetree = old;
    return this;
  };
})(jQuery, window, document);

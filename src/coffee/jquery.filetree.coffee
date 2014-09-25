((factory)->
    if typeof define is 'function' and define.amd
        define(['jquery'], factory)
    else 
        factory(jQuery)
    return
)(($) ->

    # Create the defaults once
    defaults =
        data: []
        animationSpeed : 400
        folderTrigger: "click"
        hideFiles: false
        fileContainer: null
        fileNodeName: 'name'
        folderNodeName: 'name'
        fileNodeTitle: 'name'
        folderNodeTitle: 'name'
        nodeFormatter: (node)-> node
        ajax: false
        url: "./"
        requestSettings: {}
        responseHandler: (data)-> data

    map = Array::map

    ###
        FILETREE CLASS DEFINITION
    ###
    class FileTree
        constructor: (@element, options) ->
            @settings = $.extend {}, defaults, options
            @_defaults = defaults
            @init()

        init: ->
            $root = @_getRootElement $ @element
            
            data = @settings.data

            self = @

            if @settings.ajax is true
                $.ajax( @settings.url, @settings.requestSettings)
                    .then (data) ->
                        data = self.settings.responseHandler(data)
                        self._createTree.call(self, $root, data)
            else if $.isArray(data) and data.length > 0 
                @_createTree.call(@, $root, data)
            else
                @_parseTree.call(@, $root)

            @_addListeners()
            
            data = null

            return $root

        open:(elem)->
            @_openFolder(elem)
        
        close:(elem)->
            @_closeFolder(elem)

        toggle:(elem)->
            $parent = $(elem).closest('li')
            if $parent.hasClass 'is-collapsed'
                @_openFolder(elem)
            else if $parent.hasClass 'is-expanded'
                @_closeFolder(elem)

        select:(elem)->
            $(@element).find('li.is-selected').removeClass('is-selected')
            $(elem).closest('li').addClass('is-selected')

        destroy:()->
            $(@element).off().empty()

        _getRootElement: (elem,method)->
            if $(elem).prop('tagName').toLowerCase() is 'ul'
                    $(elem).addClass('filetree')
            else if  $(elem).find('ul').length > 0
                    $(elem).find('ul').eq(0).addClass('filetree')
            else
                $(document.createElement('ul')).addClass('filetree').appendTo($(elem))

        _createTree: (elem, data)->

            $elem = $(elem)
            
            #Sort files and folders separately and combine them
            _files = []
            _folders = []

            for file in data
                if file.type is 'folder'
                    _folders.push(file)
                if file.type is 'file'
                    _files.push(file)

            _files.sort(@_nameSort)
            _folders.sort(@_nameSort)

            data = _folders.concat(_files)

            #check if given element is 'ul'
            if $elem.prop('tagName').toLowerCase() is 'ul'
                ul = $elem
            else
                ul = $(document.createElement('ul'))

            for item in data
                li = $(document.createElement('li'))
                    .addClass(item.type)

                if item.type is 'file' and @settings.hideFiles is true
                    li.addClass('is-hidden')

                a = $(document.createElement('a'))
                    .attr('href' , '#')

                if item.type is 'file'
                    a.attr('title',item[@settings.fileNodeTitle])
                        .html(item[@settings.fileNodeName])
                else if item.type is 'folder'
                    a.attr('title',item[@settings.folderNodeTitle])
                        .html(item[@settings.folderNodeName])

                for key,value of item
                    if item.hasOwnProperty(key) and key isnt 'children'
                        a.data(key, value)

                a = @settings.nodeFormatter.call(null, a)

                li.append(a)
                ul.append(li)
    
                if item.type is 'folder' and typeof item.children isnt 'undefined' and item.children.length > 0

                    li.addClass('is-collapsed').addClass('has-children')

                    arrow = $(document.createElement('button')).addClass('arrow')

                    li.prepend(arrow)

                    if @settings.hideFiles is true
                        _subfolders = $.grep(
                                        item.children
                                        (e) ->
                                            e.type is 'folder'
                                    )
                        if _subfolders.length > 0
                            li.removeClass('is-collapsed').removeClass('has-children')
                            li.find('button').removeClass('arrow').addClass('no-arrow')

                    @_createTree.call(@,li,item.children)
                
            $elem.append(ul)

        _openFolder: (elem)->
            $parent = $(elem).closest('li')

            if not $parent.hasClass 'folder'
                return false

            $a = $parent.find('a').eq(0)
            $ul = $parent.find('ul').eq(0)
            that = @

            ev_start = $.Event('open.folder.filetree')
            ev_end= $.Event('opened.folder.filetree')
            
            $a.trigger(ev_start)
            $ul.slideDown(
                that.settings.animationSpeed
                ->
                    $parent.removeClass('is-collapsed').addClass('is-expanded')
                    $ul.removeAttr('style')
                    $a.trigger(ev_end)
            )

        _closeFolder: (elem)->
            $parent = $(elem).closest('li')

            if not $parent.hasClass 'folder'
                return false
            
            $a = $parent.find('a').eq(0)
            $ul = $parent.find('ul').eq(0)
            that = @

            ev_start = $.Event 'close.folder.filetree'
            ev_end= $.Event 'closed.folder.filetree'

            $a.trigger(ev_start)
            $ul.slideUp(
                that.settings.animationSpeed
                ->
                    $parent.removeClass('is-expanded').addClass('is-collapsed')
                    $ul.removeAttr('style')
                    $a.trigger(ev_end)
            )

        _triggerClickEvent: (eventName)->
            $a = $(@)
            $root = $(@element)
            ev  = $.Event eventName, { bubbles: false }

            data = $a.data()

            ###
                Get path of the file
            ###
            if typeof data.path is 'undefined'
                path = $a.parentsUntil($root, 'li').clone().children('ul,button').remove().end()
                data.path  = map.call(path, (a)-> a.innerText).reverse().join('/')

            $a.trigger ev, data

        _addListeners: ->
            $root = $(@element)
            that = @
            
            $root.on(
                'click'
                'li.folder.is-collapsed.has-children > button.arrow'
                (event) ->
                    that._openFolder @
                    event.stopImmediatePropagation()
            )

            $root.on(
                'click'
                'li.folder.is-expanded.has-children > button.arrow'
                (event) ->
                    that._closeFolder @
                    event.stopImmediatePropagation()
            )

            $root.on(
                'click'
                'li.folder > a'
                (event) ->
                    that._triggerClickEvent.call(@, 'click.folder.filetree')
                    event.stopImmediatePropagation()
            )

            $root.on(
                'click'
                'li.file > a'
                (event) ->
                    that._triggerClickEvent.call(@, 'click.file.filetree')
                    event.stopImmediatePropagation()
            )

            $root.on(
                'click'
                'li.file, li.folder'
                (event) ->
                    event.stopImmediatePropagation()
            )

            $root.on(
                'click'
                (event) ->
                    event.stopImmediatePropagation()
            )

            $root.on(
                'dblclick'
                'li.folder > a'
                (event) ->
                    that._triggerClickEvent.call(@, 'dblclick.folder.filetree')
                    event.stopImmediatePropagation()
            )

            $root.on(
                'dblclick'
                'li.file > a'
                (event) ->
                    that._triggerClickEvent.call(@, 'dblclick.file.filetree')
                    event.stopImmediatePropagation()
            )

            return

        _parseTree: (elem)->
            $elem = $(elem)

            files = $elem.find("> li")

            for file in files
                sublist = $(file).find("> ul")
                children = $(sublist).find("> li")
                
                if children.length > 0
                    arrow = $(document.createElement('button')).addClass('arrow')
                    $(file).addClass('folder has-children is-collapsed').prepend(arrow)
                    @_parseTree item for item in sublist
                else
                    $(file).addClass('file')

            $elem.find('li > a[data-type=folder]').closest('li').addClass('folder').removeClass('file')

        _nameSort:(a,b)->
            if a.name.toLowerCase() < b.name.toLowerCase()
                -1
            else if a.name.toLowerCase() > b.name.toLowerCase()
                1
            else
                0 

    ###
        PLUGIN DEFINITION
    ###
    Plugin = (options, obj) ->
        @each ->
            $this = $(this)
            data = $this.data('$.filetree')
            
            unless data
                $this.data "$.filetree", (data = new FileTree(@, options))

            if typeof options is 'string' and options.substr(0,1) isnt '_'
                data[options].call(data,obj)

    old = $.fn.filetree

    $.fn.filetree = Plugin
    $.fn.filetree.Constructor = FileTree

    ###
        NO CONFLICT
    ###
    $.fn.filetree.noConflict = ->
        $.fn.filetree = old
        @

    return
)

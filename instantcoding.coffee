options =
  appendEditor: 'body'
  tabInsert: '  '
  evalOnKeypress: true
  css:
    attributeTypes: 'transform|filter|animation|animation-name|animation-duration|animation-timing-function|animation-delay|animation-iteration-count|animation-direction|animation-play-state|background|background-attachment|background-color|background-image|background-position|background-repeat|background-clip|background-origin|background-size|border|border-bottom|border-bottom-color|border-bottom-style|border-bottom-width|border-color|border-left|border-left-color|border-left-style|border-left-width|border-right|border-right-color|border-right-style|border-right-width|border-style|border-top|border-top-color|border-top-style|border-top-width|border-width|outline|outline-color|outline-style|outline-width|border-bottom-left-radius|border-bottom-right-radius|border-image|border-image-outset|border-image-repeat|border-image-slice|border-image-source|border-image-width|border-radius|border-top-left-radius|border-top-right-radius|box-decoration-break|box-shadow|overflow-x|overflow-y|overflow-style|rotation|rotation-point|color-profile|opacity|rendering-intent|bookmark-label|bookmark-level|bookmark-target|float-offset|hyphenate-after|hyphenate-before|hyphenate-character|hyphenate-lines|hyphenate-resource|hyphens|image-resolution|marks|string-set|height|max-height|max-width|min-height|min-width|width|box-align|box-direction|box-flex|box-flex-group|box-lines|box-ordinal-group|box-orient|box-pack|font|font-family|font-size|font-style|font-variant|font-weight|@font-face|font-size-adjust|font-stretch|content|counter-increment|counter-reset|quotes|crop|move-to|page-policy|grid-columns|grid-rows|target|target-name|target-new|target-position|alignment-adjust|alignment-baseline|baseline-shift|dominant-baseline|drop-initial-after-adjust|drop-initial-after-align|drop-initial-before-adjust|drop-initial-before-align|drop-initial-size|drop-initial-value|inline-box-align|line-stacking|line-stacking-ruby|line-stacking-shift|line-stacking-strategy|text-height|list-style|list-style-image|list-style-position|list-style-type|margin|margin-bottom|margin-left|margin-right|margin-top|marquee-direction|marquee-play-count|marquee-speed|marquee-style|column-count|column-fill|column-gap|column-rule|column-rule-color|column-rule-style|column-rule-width|column-span|column-width|columns|padding|padding-bottom|padding-left|padding-right|padding-top|fit|fit-position|image-orientation|page|size|bottom|clear|clip|cursor|display|float|left|overflow|position|right|top|visibility|z-index|orphans|page-break-after|page-break-before|page-break-inside|widows|ruby-align|ruby-overhang|ruby-position|ruby-span|mark|mark-after|mark-before|phonemes|rest|rest-after|rest-before|voice-balance|voice-duration|voice-pitch|voice-pitch-range|voice-rate|voice-stress|voice-volume|border-collapse|border-spacing|caption-side|empty-cells|table-layout|color|direction|letter-spacing|line-height|text-align|text-decoration|text-indent|text-transform|unicode-bidi|vertical-align|white-space|word-spacing|hanging-punctuation|punctuation-trim|text-align-last|text-justify|text-outline|text-overflow|text-shadow|text-wrap|word-break|word-wrap|2transform|transform-origin|transform-style|perspective|perspective-origin|backface-visibility|transition|transition-property|transition-duration|transition-timing-function|transition-delay|appearance|box-sizing|icon|nav-down|nav-index|nav-left|nav-right|nav-up|outline-offset|resize'


#    
# * CSSrefresh v1.0.1
# * 
# * Copyright (c) 2012 Fred Heusschen
# * www.frebsite.nl
# *
# * Dual licensed under the MIT and GPL licenses.
# * http://en.wikipedia.org/wiki/MIT_License
# * http://en.wikipedia.org/wiki/GNU_General_Public_License
# 

phpjs =
  array_filter: (arr, func) ->
    retObj = {}
    for k of arr
      retObj[k] = arr[k]  if func(arr[k])
    retObj

  filemtime: (file) ->
    headers = @get_headers(file, 1)
    (headers and headers["Last-Modified"] and Date.parse(headers["Last-Modified"]) / 1000) or false

  get_headers: (url, format) ->
    req = (if window.ActiveXObject then new ActiveXObject("Microsoft.XMLHTTP") else new XMLHttpRequest())
    throw new Error("XMLHttpRequest not supported.")  unless req
    tmp = undefined
    headers = undefined
    pair = undefined
    i = undefined
    j = 0
    try
      req.open "HEAD", url, false
      req.send null
      return false  if req.readyState < 3
      tmp = req.getAllResponseHeaders()
      tmp = tmp.split("\n")
      tmp = @array_filter(tmp, (value) ->
        value.toString().substring(1) isnt ""
      )
      headers = (if format then {} else [])
      for i of tmp
        if format
          pair = tmp[i].toString().split(":")
          headers[pair.splice(0, 1)] = pair.join(":").substring(1)
        else
          headers[j++] = tmp[i]
      return headers
    catch err
      return false

cssRefresh = ->
  @reloadFile = (links) ->
    a = 0
    l = links.length

    while a < l
      link = links[a]
      newTime = phpjs.filemtime(@getRandom(link.href))
      
      # has been checked before
      
      # has been changed
      
      # reload
      link.elem.setAttribute "href", @getRandom(link.href)  unless link.last is newTime  if link.last
      
      # set last time checked
      link.last = newTime
      a++
    setTimeout (->
      @reloadFile links
    ), 1000

  @getHref = (f) ->
    f.getAttribute("href").split("?")[0]

  @getRandom = (f) ->
    f + "?x=" + Math.random()

  files = document.getElementsByTagName("link")
  links = []
  a = 0
  l = files.length

  while a < l
    elem = files[a]
    rel = elem.rel
    if typeof rel isnt "string" or rel.length is 0 or rel is "stylesheet"
      links.push
        elem: elem
        href: @getHref(elem)
        last: false

    a++
  @reloadFile links

  # cssRefresh()


insertAtCursor = (myField, myValue) ->
  if myField.selectionStart or myField.selectionStart is "0"
    startPos = myField.selectionStart
    endPos = myField.selectionEnd
    myField.value = myField.value.substring(0, startPos) + myValue + myField.value.substring(endPos, myField.value.length)
    myField.selectionStart = startPos + myValue.length
    myField.selectionEnd = startPos + myValue.length
  else
    myField.value += myValue



$(document).ready ->

  cssOfDocument = ''
  for stylesheet in document.styleSheets
    for rule in stylesheet.rules
      cssOfDocument += rule.cssText
  resetCSS = 'html * { '+options.css.attributeTypes.split('|').join(': auto;\n')+' }'+cssOfDocument

  applyCSS = (css) ->
    
    $appliedCSS = $('#appliedCSS')
    unless $appliedCSS?[0]
      $('<style type="text/css" id="appliedCSS"></style>').appendTo('head')
    #   $appliedCSS.remove()
    cssRefresh()
    $appliedCSS.html(css).appendTo('head')

  # defaultStyleSheet = ''
  # $('style').each ->
  #   defaultStyleSheet += $(this).html()

  # console.log defaultStyleSheet
  # console.log document.defaultView.getComputedStyle()

  $(options.appendEditor).append """
  <div id="ic_container">
    <ul>
      <li id="ic_javascript">JavaScript</li>
      <li id="ic_coffeescript">CoffeScript</li>
      <li id="ic_css">CSS</li>
    </ul>
    <textarea id="ic_input"></textarea>
  </div>
  """

  $container = $('#ic_container')
  $tabs      = $('#ic_container ul li')
  $input     = $('textarea#ic_input')

  # $container.addClass('ellapsed') if store.get('ic_ellapsed')

  # ellapse
  $tabs.on 'click', ->
    id = $(this).attr('id')
    $container.addClass('ellapsed')
    store.set 'ic_ellapsed', true
    $tabs.removeClass('active')
    store.set 'last_used_tab', id
    $(this).addClass('active')
    $input.val store.get(id)
  # collapse
  $tabs.on 'dblclick', ->
    $container.removeClass('ellapsed')
    store.set 'ic_ellapsed', false

  $input.on 'dblclick', ->
    $container.toggleClass('fullscreen')
    store.set 'ic_ellapsed', false

  $input.on 'keydown', (e) ->
    $currentTab = $('#ic_container ul li.active')
    id = $currentTab.attr('id')
    before  = store.get(id) or ''
    current = $(this).val()
    if before.trim() isnt current.trim()
      store.set id, current
    else unless e.keyCode is 13 and e.ctrlKey and e.shiftKey
      return
    
    # TAB
    if event.keyCode is 9
      e.preventDefault()
      insertAtCursor this, options.tabInsert
    # ENTER + CTRL
    else if ( e.keyCode is 13 and e.ctrlKey and e.shiftKey )
    # else if options.evalOnKeypress
      evalJS = false
      evalCSS = false
      if id is 'ic_coffeescript'
        CoffeeScript.eval(current)# if /^(13|38|40)$/.test(String(e.keyCode))
      else if id is 'ic_javascript'
        eval(current)# if /^(13|38|40)$/.test(String(e.keyCode))
      else if id is 'ic_css'
        evalCSS = current
      if evalCSS
        applyCSS(evalCSS)

  $container.find('ul li').each ->
    $(this).html($(this).html().replace(/([a-z]{1})/gi, '$1<br />'))

  $input.on 'change', ->
    # id = $('#ic_container ul li.active').attr('id')
    # store.set id, $(this).val()

  if store.get('ic_ellapsed')
    if store.get('last_used_tab')
      $container.find("ul li##{store.get('last_used_tab')}").click()#addClass('active')
    else
      $container.find("ul li:first").click()

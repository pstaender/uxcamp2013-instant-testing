throw 'CoffeeScript is needed' unless CoffeeScript?

class DocumentStyle

  _import: []
  _tree: {}
  _levels: []
  eval: null
  _environments: {}

  begin: '# csss definition starts here'

  init: ->
    @_levels = []

  # copy + paste from underscore
  _extend: (obj) ->
    has = (obj, key) -> Object::hasOwnProperty.call(obj, key)
    each = (obj, iterator, context) ->
      return  unless obj?
      if Array::forEach and obj.forEach is Array::forEach
        obj.forEach iterator, context
      else if obj.length is +obj.length
        i = 0
        l = obj.length
        while i < l
          return  if iterator.call(context, obj[i], i, obj) is breaker
          i++
      else
        for key of obj
          return  if iterator.call(context, obj[key], key, obj) is breaker  if _.has(obj, key)
    each Array::slice.call(arguments, 1), (source) ->
      if source
        for prop of source
          obj[prop] = source[prop]
    obj

  import: (file) ->
    @_import.push(file)

  use: (yourClassName) ->
    yourClass = @_environments[yourClassName]
    if yourClass and typeof yourClass is 'function'
      DocumentStyle::_extend(@,new yourClass)
    else
      throw new Error("Couldn't find/use '#{yourClassName}'")

  add: ->
    args = Array.prototype.slice.call(arguments)
    @_levels.push(args)

  addEnvironment: (yourClass) ->
    if typeof yourClass is 'function'
      className = yourClass.toString()?.split('\n')?[0].replace(/^function\s(.+?)\(.*/, '$1')
      @_environments[className] = yourClass

  media: (query) ->
    @add '@media', query


class MyEnvironment

  myPadding: ->
    ( 12 + 'px' )

DocumentStyle::addEnvironment(MyEnvironment)

class CSSS

  original: null
  source: null
  styletext: null
  coffeescript: null
  javascript: null
  context: null
  evaluated: null
  tree: {}
  declarationPart: null
  seperateDeclarations: true # TODO: make that obsolete

  attributesTypes: 'animation|animation-name|animation-duration|animation-timing-function|animation-delay|animation-iteration-count|animation-direction|animation-play-state|background|background-attachment|background-color|background-image|background-position|background-repeat|background-clip|background-origin|background-size|border|border-bottom|border-bottom-color|border-bottom-style|border-bottom-width|border-color|border-left|border-left-color|border-left-style|border-left-width|border-right|border-right-color|border-right-style|border-right-width|border-style|border-top|border-top-color|border-top-style|border-top-width|border-width|outline|outline-color|outline-style|outline-width|border-bottom-left-radius|border-bottom-right-radius|border-image|border-image-outset|border-image-repeat|border-image-slice|border-image-source|border-image-width|border-radius|border-top-left-radius|border-top-right-radius|box-decoration-break|box-shadow|overflow-x|overflow-y|overflow-style|rotation|rotation-point|color-profile|opacity|rendering-intent|bookmark-label|bookmark-level|bookmark-target|float-offset|hyphenate-after|hyphenate-before|hyphenate-character|hyphenate-lines|hyphenate-resource|hyphens|image-resolution|marks|string-set|height|max-height|max-width|min-height|min-width|width|box-align|box-direction|box-flex|box-flex-group|box-lines|box-ordinal-group|box-orient|box-pack|font|font-family|font-size|font-style|font-variant|font-weight|@font-face|font-size-adjust|font-stretch|content|counter-increment|counter-reset|quotes|crop|move-to|page-policy|grid-columns|grid-rows|target|target-name|target-new|target-position|alignment-adjust|alignment-baseline|baseline-shift|dominant-baseline|drop-initial-after-adjust|drop-initial-after-align|drop-initial-before-adjust|drop-initial-before-align|drop-initial-size|drop-initial-value|inline-box-align|line-stacking|line-stacking-ruby|line-stacking-shift|line-stacking-strategy|text-height|list-style|list-style-image|list-style-position|list-style-type|margin|margin-bottom|margin-left|margin-right|margin-top|marquee-direction|marquee-play-count|marquee-speed|marquee-style|column-count|column-fill|column-gap|column-rule|column-rule-color|column-rule-style|column-rule-width|column-span|column-width|columns|padding|padding-bottom|padding-left|padding-right|padding-top|fit|fit-position|image-orientation|page|size|bottom|clear|clip|cursor|display|float|left|overflow|position|right|top|visibility|z-index|orphans|page-break-after|page-break-before|page-break-inside|widows|ruby-align|ruby-overhang|ruby-position|ruby-span|mark|mark-after|mark-before|phonemes|rest|rest-after|rest-before|voice-balance|voice-duration|voice-pitch|voice-pitch-range|voice-rate|voice-stress|voice-volume|border-collapse|border-spacing|caption-side|empty-cells|table-layout|color|direction|letter-spacing|line-height|text-align|text-decoration|text-indent|text-transform|unicode-bidi|vertical-align|white-space|word-spacing|hanging-punctuation|punctuation-trim|text-align-last|text-justify|text-outline|text-overflow|text-shadow|text-wrap|word-break|word-wrap|2transform|transform-origin|transform-style|perspective|perspective-origin|backface-visibility|transition|transition-property|transition-duration|transition-timing-function|transition-delay|appearance|box-sizing|icon|nav-down|nav-index|nav-left|nav-right|nav-up|outline-offset|resize'

  pattern:
    isInlineOperation: /\s+([a-zA-Z0-9\(]+[\(\)\%\/\*\+\-\.\s]*)+\s*$/
    detectUnit: /[0-9]+(\.[0-9]+)*(in\b|cm\b|mm\b|em\b|ex\b|pt\b|pc\b|px\b|s\b|\%)/
    # TODO: improve isLineSelector
    isLineSelector: /^[a-z\.\#\&]+[a-z0-9\,\s\#\*\:\>\[\]\=\~\+\.\(\)\-\"\']*$/i
    isLineAttribute: /^(\s+)([a-zA-Z\-]+)(\:|\s){1}/
    comments: -> /(#\s.*|\/\/.*)?\n/g
    isMediaQuery: /^(\@media)\s+(.*)$/
    isCSSValue: /^([0-9\.]+(in|cm|mm|em|ex|pt|pc|px|s|\%))$/
    hasOperator: -> /\s[\+\-\/\*\%]{1}\s/g
    isNotParsableValue: /^([0-9]+(\.[0-9])*|\@*[a-zA-Z\_]+)$/ 
    doesLineBeginWithAttribute: null
    processPartsSeperator: /\n@begin\n/
    cssColorValues: ->
      #return /\s(\#[a-z0-9]{3,6})\s*/g
      /\s(\#[a-z0-9]{3,6}|AliceBlue|AntiqueWhite|Aqua|Aquamarine|Azure|Beige|Bisque|Black|BlanchedAlmond|Blue|BlueViolet|Brown|BurlyWood|CadetBlue|Chartreuse|Chocolate|Coral|CornflowerBlue|Cornsilk|Crimson|Cyan|DarkBlue|DarkCyan|DarkGoldenRod|DarkGray|DarkGreen|DarkKhaki|DarkMagenta|DarkOliveGreen|Darkorange|DarkOrchid|DarkRed|DarkSalmon|DarkSeaGreen|DarkSlateBlue|DarkSlateGray|DarkTurquoise|DarkViolet|DeepPink|DeepSkyBlue|DimGray|DimGrey|DodgerBlue|FireBrick|FloralWhite|ForestGreen|Fuchsia|Gainsboro|GhostWhite|Gold|GoldenRod|Gray|Green|GreenYellow|HoneyDew|HotPink|IndianRed|Indigo|Ivory|Khaki|Lavender|LavenderBlush|LawnGreen|LemonChiffon|LightBlue|LightCoral|LightCyan|LightGoldenRodYellow|LightGray|LightGreen|LightPink|LightSalmon|LightSeaGreen|LightSkyBlue|LightSlateGray|LightSteelBlue|LightYellow|Lime|LimeGreen|Linen|Magenta|Maroon|MediumAquaMarine|MediumBlue|MediumOrchid|MediumPurple|MediumSeaGreen|MediumSlateBlue|MediumSpringGreen|MediumTurquoise|MediumVioletRed|MidnightBlue|MintCream|MistyRose|Moccasin|NavajoWhite|Navy|OldLace|Olive|OliveDrab|Orange|OrangeRed|Orchid|PaleGoldenRod|PaleGreen|PaleTurquoise|PaleVioletRed|PapayaWhip|PeachPuff|Peru|Pink|Plum|PowderBlue|Purple|Red|RosyBrown|RoyalBlue|SaddleBrown|Salmon|SandyBrown|SeaGreen|SeaShell|Sienna|Silver|SkyBlue|SlateBlue|SlateGray|Snow|SpringGreen|SteelBlue|Tan|Teal|Thistle|Tomato|Turquoise|Violet|Wheat|White|WhiteSmoke|Yellow|YellowGreen)\s*/ig
    variableWithUnit: -> /^(\@[a-zA-Z\_]+)\[(in|cm|mm|em|ex|pt|pc|px|s|\%)\]/g

  constructor: (@original = null) ->

  createContext: ->
    @context = new DocumentStyle()

  transformCssObjectsToJSON: (s, options = {}) ->
    # TODO: refactor
    {replace} = options
    replace  ?= true
    css = []
    whiteSpacesCount = null
    lines = s.split('\n')
    whiteSpaces = null
    currentWhiteSpacesCount = null
    for line, i in lines
      whiteSpaces ?= line.match(/^(\s+)/)?[1]
      currentWhiteSpacesCount ?= whiteSpaces?.length || null
      lineBeginsWithAttribute = @doesLineBeginsWithAttribute(line)
      if currentWhiteSpacesCount > 0
        if whiteSpacesCount isnt currentWhiteSpacesCount or lineBeginsWithAttribute isnt true
          css = []
          whiteSpacesCount ?= currentWhiteSpacesCount
          whiteSpaces = null
        if lineBeginsWithAttribute
          whiteSpaces ?= line.match(/^(\s+)/)?[1] || ''
          if css.length is 0
            # begin
            l = whiteSpaces + "o =\n"
            # inc whitespace
            whiteSpaces += '  '
            whiteSpacesCount = currentWhiteSpacesCount = whiteSpacesCount + 2
            lines[i] = l + @parseAttributeLine(line, { indent: whiteSpaces, escape: true })
            css.push(parsed)
          else
            whiteSpacesCount = currentWhiteSpacesCount        
            parsed = @parseAttributeLine(line, { indent: whiteSpaces, escape: true } )
            lines[i] = parsed if replace
            css.push(parsed) if lineBeginsWithAttribute
    if replace then lines.join('\n') else css

  escapeCSSValue: (s) ->
    s?.replace /\'/g, "\\'"

  operateInline: (s, options = {}) ->
    {onlyIfOperatorsExists, enclose, escape} = options
    escape ?= false  
    # no enclosement if we have an @access here, removed
    if s
      # remove trailing whitespaces
      # s = String(s).replace /\s+$/, ''
      s = String(s).trim(s)
      # no escaping if we have a number or a variable
      enclose ?= false if /^[0-9]+(\.[0-9]+)*$/.test(s) or /^\s*(@[a-zA-Z\_]+(\(.*?\))*\s*)+$/.test(s)
      # exclude '@method()' from escape
      # enclose result in ''
      enclose ?= true
      # we don't need an operator for ident if we have css value here
      onlyIfOperatorsExists ?= false if @pattern.isCSSValue.test(s)
      onlyIfOperatorsExists ?= true
      
      hasOperators = @pattern.hasOperator().test(s)

      # detect units and transform if found
      if @pattern.variableWithUnit().test(s)
        # @r[px] -> @r + 1px
        escape = enclose = false
        s = s.replace(@pattern.variableWithUnit(), "$1 + '$2'")

      # enclose?, only if no operator are found
      if not hasOperators and /(@[a-zA-Z\_]+(\(.*?\)))/.test(s)
        enclose ?= true
        if enclose
          s = @escapeCSSValue(s) if escape
          s = "'#{s}'"
          return s.replace(/(@[a-zA-Z\_]+)(\(.*?\))/g, " ' + $1$2 + ' ")

      if onlyIfOperatorsExists and not hasOperators
        s = @escapeCSSValue(s) if escape
        return if enclose
          "'#{s.replace(/(\s@[a-zA-Z]+)(\(.*?\))*\s/g, " ' + $1$2 + ' ")}'"
        else
          "#{s}"



      # do nothing if we have a string or a number -> '...' or "..."
      return s if /^(\'.*\'|\".*\")$/.test(s)
      # extract unit
      unit  = s.match(@pattern.detectUnit)?[2] || null
      if unit
        # remove unit from string
        # and enclose in brackets
        s = "( #{s.split(unit).join('')} + '#{unit}' )"
      else
        s = "( #{s.split(unit).join('')} )"
    else
      s = ''
    s

  seperateDeclarationAndStyle: ->
    @source          = ''
    @declarationPart = ''
    styletext        = ''
    declarationPart  = ''
    
    setBeginIfNotFound = '@begin'
    @original = '\n'+@original # makes pattern with \n work
    # if we have a @begin we use this to split
    useMediaQueryAsSeperator = true
    splitPattern = @pattern.processPartsSeperator
    found = @original.match(splitPattern)
    if not found and useMediaQueryAsSeperator
      @original = @original.replace(/\n@media\s/, "\n#{setBeginIfNotFound}\n@media ")
      found = @original.match(splitPattern)
    if found
      [declarationPart, styletext] = @original.split(splitPattern)
      styletext = "\n#{found[0]}\n" + styletext
    # else we try to detect first occurrence of selector and seperate this way 
    else
      #if setBeginIfNotFound
      #  styletext = setBeginIfNotFound + '\n' + @original
      #else
      declarationsEnds = null
      for line in @original.split('\n')
        declarationsEnds = true if @pattern.isLineSelector.test(line) or @pattern.isMediaQuery
        # console.log line, @pattern.isLineSelector.test(line)
        unless declarationsEnds
          declarationPart += '\n'+line
        else 
          styletext += '\n'+line

    @styletext = styletext
    @declarationPart = declarationPart

  processDeclaration: ->
    @declarationPart = @transformCssObjectsToJSON(@declarationPart, {replace: true,})
    # process declaration part
    declarationPart = for line, i in @declarationPart.split('\n')      
      unless /(\'.*\')|(\".*\")/.test(line)
        # escape color values like @color = #fff or rgba(0,0,0,0.5)
        line = line.replace(@pattern.cssColorValues(), " '$1' ")
        # line = line.replace(/\s(rgb[a]*\([\s0-9\.\,]+\))/g, " '$1' ")
      # catch all unspecific value
      if @pattern.isInlineOperation.test(line)
        parts = line.match(/^(\s*)(.*?\=\s*)(.*)$/,line)
        if parts?[3]
          line = parts[1] + parts[2] + @operateInline(parts[3], {enclose: false}) # no enclosement here!
        else
          line = line.match(/^\s*/)?[0] + @operateInline(line, {enclose: false})
      line

    @declarationPart = declarationPart.join('\n').trim()

  doesLineBeginsWithAttribute: (line) ->
    if @pattern.doesLineBeginWithAttribute
      regex = @pattern.doesLineBeginWithAttribute
    else
      # generate pattern
      regexString = @attributesTypes.split('-').join('\\-')#.replace(/([a-z\-]+)/g, '($1)')
      regexString = "^\\s+(\\-moz\\-|\\-ms\\-|mso\\-|\\-khtml\\-|\\-webkit\\-|\\-o\\-){0,1}(#{regexString}){1}"
      regex = @pattern.doesLineBeginWithAttribute = new RegExp(regexString)
    regex.test(line)

  parse: (s) ->    
    @original = s if s
    if @original
      # remove comments,  starting with # ...
      # TODO: better solution
      @original = @original.replace(@pattern.comments(),'\n').replace(/\n{3,}/g, '\n\n')
      # seperate declaration and stylesheet part
      # for better parsing (will be obsolete in future with better parsin)
      @seperateDeclarationAndStyle() if @seperateDeclarations

      @processDeclaration()
      
      styletext = '\n'+@cleanup(@styletext)

      lines = for line in styletext.split('\n')
        # media queries have an exception rule
        if @pattern.isMediaQuery.test(line)
          # @media
          matches = line.match(@pattern.isMediaQuery)
          if matches?[2]
            line = "#{matches[1]} #{@operateInline(matches[2])}"
        # attributes
        # color: 'black'
        else if @doesLineBeginsWithAttribute(line)
          line = @parseAttributeLine(line, { indent: '  ', escape: true }) # we have an escape for e.g. font: 'Lucida', Arial
        else
          line = @parseInlineArguments(line)
          # functions, like `@pad('5px')`
          line = line.replace /^(\s+)(\@[a-zA-Z]+\(.*\))/g, '\n  $2'
          # many selectors, like `.a, i[t="ok"], #sidebar p:first-line, ul li:nth-child(3)`
          line = line.replace /^(\s*)([a-zA-Z\.\#\&\>\:]+((?!\:\s).)*)$/, "\n@add '$2', '$1', "
          # one selector, like `body.imprint`
          line = line.replace /\n(\s*)([a-zA-Z\.\#\&\>]+((?!\:\s).)*)(\s*)$/, "\n@add '$2', '$1', $4"


      styletext = lines.join('\n').replace(/\n+/g, "\n")
      # if we have @add of selector with no properties: (TODO: find a better way instead of using regex/replace)
      # tr:hover
      #   a ...
      styletext = styletext.replace /(\n@add\s.+?)(\,\s[\n])(@add\s)/g, '$1\n$3'
      @source = @declarationPart + '\n\n' + styletext.trim()
      @source = @source.trim()
      @compile()

  parseAttributeLine: (line, options = {}) ->
    {indent} = options
    indent  ?= line.match(/^(\s+)/)[1] || ''# if indent is set with '  ' whitespace, all will be intend
    # split into attribute and value(s)
    m = line.match /^(\s+)([a-zA-Z\-]+)(\:|\s){1}\s*(.+)$/#, '\n  $2:
    value = m?[4]?.trim()
    attr  = m?[2]
    if value# do we have a value here?
      # if not in '' we try to cast a value
      unless /^\'.*\'$/.test(value)
        value = @operateInline(value, options)#, enclose: true)
        value = value.replace(/\+\'\)$/, ')')
        value = @parseInlineArguments(value)
      "#{indent}'#{attr}': #{value}"
    else
      line.replace /^(\s+)([a-zA-Z\-]+)/, "#{indent}'$2':"

  parseInlineArguments: (line) ->    
    methodsFound = line.match /@[a-zA-Z\_]+\(.+\)/g
    if methodsFound
      for method in methodsFound
        # s.th. like @width(80%)
        parts = method.match /^(@[a-zA-Z\_]+)\(([a-zA-Z0-9\%]+)\)/
        if parts?[2]
          # replace
          value = parts[2]
          argument = if @pattern.isNotParsableValue.test(value) then value else @operateInline(value, enclose: true)
          line = line.split(parts[0]).join(parts[1]+"(#{argument})")
    line

  compile: ->
    @declarationPart = null
    pre = ''
    try
      @javascript = CoffeeScript.compile(pre+@source)
      @coffeescript = pre+'\n\n  '+@source.split('\n').join('\n  ')+'\n\n'
    catch e
      @error(e)
      @source

  eval: (context) ->
    @createContext() unless @context? 
    if @context
      if window
        # TODO: find a better way than that, figure out with sandbox
        # for now, attach document as context to coffeescript
        CoffeeScript.__csss_context = @context
      @coffeescript = """
      doc = CoffeeScript.__csss_context || this
      rgba = -> 'rgba('+Array.prototype.slice.call(arguments).join(", ")+')'
      rgb  = -> 'rgb('+Array.prototype.slice.call(arguments).join(", ")+')'
      doc.init()
      doc.eval = ->
        #{@coffeescript}
      doc.eval()
      doc
      """
      @evaluated = CoffeeScript.eval(@coffeescript)
    else
      CoffeeScript.eval(@coffeescript, sandbox: @context)

  cleanup: (s) ->
    # cleanup (TODO: better rules or remove)
    # * remove optional `;` and `{` `}`
    # * remove empty lines
    # * tabs to spaces
    s = "\n"+s.replace(/\n+/g, "\n")
    s = s.replace /\;[^\S\n]*/g, ''
      #.replace /\s*\}[^\S\n]*/g, ''
      #.replace /\n(.+?)\s+\{[^\S\n]*/g, '\n$1'
      .replace /\t/g, '  '
    s.trim()

  error: (e) ->
    @_error = e if e?
    @_error?.message || @_error || null

  css: (cssString = '', o = null) ->

    levels = {}

    levelBefore = null
    selectorBefore = ''

    _objectToCSS = (o) ->
      parts = for attribute of o
        # we only escape on content attribute, or are there maybe more?
        escape = if attribute is 'content' then "'" else ''
        "#{attribute}: #{escape}#{o[attribute]}#{escape};"
      if parts.length > 0 then '{ '+parts.join('\n')+' }' else null

    mediaQuery = null

    for section in @evaluated?._levels
      if section[0] is '@media'
        cssString += ' } ' if mediaQuery
        cssString += "\n@media #{section[1]} {"
        mediaQuery = section[1]
      else

        selector         = selectorString = section[0]
        level            = Math.floor section[1].length / 2
        values           = _objectToCSS(section[2])
        isReference      = selectorString[0] is '&'

        if section.length > 2
          # we have mixins here
          # apply on the current selector
          for i in [3...section.length]
            DocumentStyle::_extend(section[2], section[i])

        if level < levelBefore and isReference and levels?[level-1]
          selectorString = levels[level-1].trim() + selectorString.trim().substring(1)# || ''
        else if level >= levelBefore
          if isReference
            # we have a reference here, merge together
            parts = for s in selectorString.substring(1).split(',')
              s = ' '+s if /^[a-z]+/.test(s)
              insideParts = for _s in levels[level-1].trim().split(',')
                _s.trim()+s.replace(/\s([^a-zA-Z])/g,'$1').replace(/\s([a-zA-Z]+.+)/g,' $1') if _s?.trim()
              insideParts.join(', ').replace(/\,\s$/,'')
            selectorString = parts.join(', ').replace(/\,\s$/,'')
          else
            before = levels[level-1]?.trim()
            selectorString = selectorString.trim()
            selectorString = ' ' + selectorString unless /^[\.\#\:]{1}/.test(selectorString.trim())
            selectorString =  ( before || '' ) + ' ' + selectorString.trim()

        cssString += "\n#{selectorString} #{_objectToCSS(section[2])}" if values
        if level isnt levelBefore
          levelBefore = level
          selectorBefore = selectorString
        
        levels[level] = selectorString

    cssString += " } " if mediaQuery # close {}
    cssString


if window
  window.CSSS ?= CSSS
else
  exports = CSSS



examples = []

examples.push """
@myColorSchema =
  color #ddd
  background #333
  text-shadow 1px 1px 0 #111

@padding = 2
@borderWidth = 2px

# @begin is optional if you use @media

@begin

@media all

body
  background #eee

textarea
  padding @padding * 10px
  border
    @borderWidth
    solid
    #ccc
"""

examples.push """
@use 'mobile'
# coffeescript comments can be used
# but with a leading #[space] to avoid ambiguity with `#selector`
//alternative: doubleslash comments

# you can define methods
@padding  = (pixels) ->
  pixels * 2
# variables with all kind of css units
@smallerFontSize = 12em / 2
@width    = 1200px * 0.8
# color values
@grey     = rgba(60,60,60,0.4)
@errorRed = #ffa1a1
# compute (like in coffeescript)
@height = ->
  pi = Math.PI
  120% / ( 5 * pi )
@bold = (s) ->
  if s is 'bolder' then 600 else 400

# keep it dry with objects used as mixins
@borderRadius = (@r) ->
  -webkit-border-radius @r[px]
  -moz-border-radius @r - 1px
  -o-border-radius @r * 4px
  border-radius @r[px]

@filter = (val) ->
  val * 20%

# optional, but recommend
# start your stylesheet definition with a @begin
# (not needed if you don't define methods/vars

@begin

@media @mobileDevices()

a 
  color #fff
  background @test
  # mixin example
  @borderRadius(2)

  &:hover
    opacity @filter(0.2)
    border 1px 20px solid

tr.even
  background-color red
    .a
      padding: @padding(12px) * 3px # `:` are optional
      font-weight @bold('bolder') - 100
"""

$(document).ready ->

  $in     = $('#in')
  $css    = $('#out pre code')
  $coffee = $('#coffeescript pre code')
  $trans  = $('#transscript pre code')
  $error  = $('#error')

  timestamp = -> Math.round( new Date().getTime() / 1000 )


  csss = new CSSS()


  # testing out using your own enviornments
  class mobile

    darkColorSchema: ->
      o =
        'color': '#eee'
        'background': '#444'
        'text-shadow': '1px 1px 0px #000'

    mobileDevices: -> 'screen and (max-device-width: 480px)'

  csss.use mobile

  lastUse = stash.get 'lastUse'
  lastUse ?= timestamp()

  options =
    BeautifyCSS: true
    SyntaxHighlighting: true
    ApplyOnDocument: false

  $options = $('#BeautifyCSS, #SyntaxHighlighting, #ApplyOnDocument')
  $options.each ->
    id = $(this).attr('id')
    $o = $(this)
    options[id] = stash.get(id) if stash.get(id)?
    $o.prop('checked', options[id])
    $o.on 'change', ->
      options[id] = $o.prop('checked')
      stash.set id, options[id]
      # renew
      parse(true)

  if ( timestamp() - lastUse ) > 3600
    # use default code
    exampleCode = ''
  else
    # load stashed input
    exampleCode = if stash.get('input') then stash.get('input') else examples[0]

  $exampleSelect = $('#LoadExample')
  
  for i in [0...examples.length]
    $exampleSelect.append("<option value=\"#{i}\"># #{i}</option>")

  $('#LoadExample').on 'change', ->
    $in.text(examples[$(this).val()])
    parse(true)

  $('#ClearCode').on 'click', ->
    stash.set 'input', ''
    $in.text('')
    clearFields()
    #parse(true)

  $in.text(exampleCode)

  applyCssToDocument = (css) ->
    $('#AppliedCSS').remove()
    reset = """
    html * { #{CSSS::attributesTypes.split('|').join(': auto;\n')} }
    """
    $('<style type="text/css" id="AppliedCSS">'+reset+'</style>').html(css).appendTo('head')

  displayError = (error) ->
    if error
      text = (String) error?.message || error
      if text?.trim()
        $error.text(text)
        return $error.removeClass('hidden')
    $error.addClass('hidden')

  clearFields = ->
    $coffee.html('')
    $css.html('')
    $trans.html('')

  parse = (force = false) ->
    lastUse = timestamp()
    return if force isnt true and stash.get('input')?.trim() is $in.val()?.trim() 
    error = []
    csss.error('')

    clearFields()
    
    try
      csss.parse $in.val()
    catch e
      firstLineNumber = e.location?.first_line or null
      firstLine = csss.source.split('\n')?[firstLineNumber]?.trim() if firstLineNumber
      error.push(new Error("Parsing Error #{if firstLineNumber then "@line #{firstLineNumber}: `#{firstLine}" else ""}"))
      error.push(e)

    if options.SyntaxHighlighting 
      $trans.html hljs.highlight('coffeescript', csss.source).value
    else
      $trans.text csss.source

    try
      css = csss.css()
      css = cssbeautify(css, indent: '  ') if options.BeautifyCSS
      applyCssToDocument(css) if options.ApplyOnDocument
      if options.SyntaxHighlighting
        $css.html  hljs.highlight('css', css).value
      else
        $css.text(css)

      coffeescript = csss.coffeescript || csss.declarationPart + csss.source
      if options.SyntaxHighlighting
        $coffee.html hljs.highlight('coffeescript', coffeescript).value
      else
        $coffee.text(coffeescript)
    catch e
      error.push(new Error('Evaluating Error'))
      $coffee.html('')
      console.error e
      error.push(e)

    # store input
    stash.set('input', $in.val())
    if csss.error()
      $coffee.html('') # no output if error
      error.push(csss.error())
      console.error csss.error()
    displayError(error)

  parse(true)

  $collapsableContainer = $('.textarea, #options')

  $collapsableContainer.each ->
    if stash.get $(this).attr('id')+'.collapsed'
      $(this).addClass('collapsed')
    else
      $(this).removeClass('collapsed')

  $collapsableContainer.on 'dblclick', ->
    $(this).toggleClass('collapsed')
    stash.set $(this).attr('id')+'.collapsed', (Boolean) $(this).hasClass('collapsed')

  $in.on 'keyup', (e) ->
    key = e.keyCode
    allowedKey = [ 13, 38, 40 ] #37 is <-
    parse() if allowedKey.indexOf(key) isnt -1

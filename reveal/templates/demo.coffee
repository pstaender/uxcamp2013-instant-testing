$('#input').unbind 'keyup'
$('#input').on 'keyup', ->
  $(this).val $(this).val().replace(/(.{1})/g,' $1').replace(/\s+/g,' ').trim()

$('#c2a').unbind 'click'
$('#c2a').attr 'disable', 'disable'
$('#c2a').on 'click', ->
  $('#input').val $('#input').val().replace(/\s+/g,'')

$('#input').unbind 'keyup'

buttonText = 'Submit Paragraph'
$('#input').on 'keyup', ->
  text = $(this).val()
  wordsCount = text.match(/([a-z]+)?\s/ig)

  isValid = false
  if wordsCount?.length > 3 and /[a-z]+\./.test(text)
    isValid = true
  
  paragraphsCount = text.match(/[a-z]+\./g).length or 0

  if paragraphsCount > 1
    $('#c2a').text("Submit #{paragraphsCount} Paragraphs")
  else
    $('#c2a').text(buttonText)

  unless isValid
    $("#example").addClass('error')
  else 
    $("#example").removeClass('error')

$('#input').keyup()
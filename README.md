# INSTANT TESTING
## Presentation slides from 23th June 2013, UXCamp 2013 Berlin

## Keyboard Shortcuts 

**Double Click on the tabs** `JavaScript`, `CoffeeScript` or `CSS` opens or closes the small editor view.
**Double Click on the editor textfield** switches to fullscreen mode and back.
**Click on the tab** switches to the tab.
**Ctr + Shift + Enter** evaluates the code

Tested with Chrome and Safari (June 2013)

## Slides

You can review and test the slides "live" on

  http://pstaender.github.io/uxcamp2013-instant-testing/slides/

## Embed "Instant Coding" in your HTML file

Instand Coding depends on the following Libraries: jQuery, CoffeeScript, underscore and StoreJS.

Here is a ready to use template for the header:

```html
  <!-- depenedencies -->
  <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
  <script src="http://coffeescript.org/extras/coffee-script.js"></script>
  <script src="http://underscorejs.org/underscore-min.js"></script>
  <script src="http://marcuswestin.github.io/store.js/store.js"></script>
  <!-- /depenedencies -->
  <script src="http://pstaender.github.io/uxcamp2013-instant-testing/instantcoding.coffee" type="text/coffeescript"></script>
  <link  href="http://pstaender.github.io/uxcamp2013-instant-testing/instantcoding.css" rel="stylesheet" type="text/css" />
```
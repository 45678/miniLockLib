if location.hostname is "45678.github.io" and location.protocol isnt "https:"
  window.location = location.toString().replace("http:", "https:")

$(document).ready (event) ->
  hljs.highlightBlock(pre) for pre in document.querySelectorAll("pre")

$(document).ready (event) ->
  renderID location.hash.replace("#", "") if location.hash

$(document).on "click", "a[href^='#']", (event) ->
  renderID event.target.href.toString().split("#")[1]

renderID = (id) ->
  el = document.getElementById(id)
  $("*.selected").removeClass("selected")
  $("a[href='##{id}']").addClass("selected")
  $(el).next("h2").addClass("selected")

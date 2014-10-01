if location.hostname is "45678.github.io" and location.protocol isnt "https:"
  window.location = location.toString().replace("http:", "https:")

$(document).ready (event) ->
  for pre in document.querySelectorAll("pre")
    pre.classList.add("js") if pre.classList.contains("ecmascript")
    hljs.highlightBlock(pre)

$(document).ready (event) ->
  if location.hash
    id = location.hash.replace("#", "")
    render({id})

$(document).on "click", "a[href^='#']", (event) ->
  id = event.currentTarget.href.toString().split("#")[1]
  render({id})

$(document).on "mouseover", "body > header, #introduction, #setup, #examples", (event) ->
  baseURL = location.toString().split("#")[0]
  history.replaceState({}, "", baseURL) if location.hash
  render()

$(document).on "mouseover", "body > article, article > div", (event) ->
  id = event.currentTarget.querySelector("a[id]").id
  baseURL = location.toString().split("#")[0]
  history.replaceState({}, "", "#{baseURL}##{id}") unless location.hash is "##{id}"
  render({id})

render = (options={}) ->
  $("*.selected").removeClass("selected")
  if options.id
    $("a[href='##{options.id}']").addClass("selected")
    $(document.getElementById(options.id)).next("h1, h2").addClass("selected")

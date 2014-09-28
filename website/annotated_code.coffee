if location.hostname is "45678.github.io" and location.protocol isnt "https:"
  window.location = location.toString().replace("http:", "https:")

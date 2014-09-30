exports.isAcceptable = (emailAddress) ->
  EmailAddressPattern.test(emailAddress)

EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\.[A-Z]{2,20}/i

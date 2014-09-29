EmailAddressPattern = /[-0-9A-Z.+_]+@[-0-9A-Z.+_]+\.[A-Z]{2,20}/i

# miniLock only accepts standards compliant email addresses.
exports.isAcceptable = (emailAddress) ->
  EmailAddressPattern.test(emailAddress)

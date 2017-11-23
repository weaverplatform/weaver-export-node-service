class DCError
  @UNKNOWN       = 1
  @NOT_FOUND_ABS = 2
  @NOT_FOUND_DC  = 3

  constructor: (@code, @message) ->

module.exports = DCError

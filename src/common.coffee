awsPromised = require('aws-promised')
gm = require('gm').subClass({ imageMagick: true })

# This is stolen from `Q-extended` but we inline it here because
# generator stuff needs to be transpiled
Q.genrun = (generator) -> Q.async(generator)()

partial = (fn, partialargs...) ->
  (args...) ->
    args = partialargs.concat(args)
    fn(args...)

module.exports = {Q, awsPromised}
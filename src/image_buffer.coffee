
{Q, gm} = require './common'

imageType = "png"

# Resizes to a `jpeg` buffer with given width, as promised

resize = (buffer, fileName, width) ->
  Q.promise (resolve, reject, notify) ->
    onBuffer = (err, data) ->
      if err then return reject(err)
      resolve(data)
    gm(buffer, fileName).resize(width).toBuffer(imageType, onBuffer)

module.exports = {resize}

      
# Poor man's testing

if not module.parent 
  genrun = require('q-extended').genrun
  genrun ->
    fs = require 'fs'
    data = fs.readFileSync 'test.png'
    data = yield resize(data, 150)
    console.log  "asd" + data
  .catch (e) -> console.log e, e.stack.split('\n')
  
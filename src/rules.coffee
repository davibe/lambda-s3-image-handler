# Given an image named `testimage.*` we want to create 3 variants
# - `large` -> testimage.jpg: with a width of 500px
# - `medium` -> testimage._SL160_.jpg: with a width of 160px
# - `small` -> testimage._SL75_.job: with a width of 75px

extSplit = (fileName) ->
  fileName = fileName.split('.')
  ext = fileName.pop()
  fileNameNoExt = fileName.join('.')
  [ext, fileNameNoExt]

isNotAnOriginal = (fileName) ->
  # Is the current file the original or one of the generated variants ?
  # This is used to skip files that should not be re-converted
  tokens = ["_SL75_.jpg", "_SL160_.jpg"]
  for token in tokens
    if fileName.indexOf(token) != -1
      return true
  false

generateVariants = (fileName) ->
  [originalExt, originalName] = extSplit(fileName)
  ext = "jpg"
  result =
    large:
      fileName: "#{originalName}.#{ext}"
      width: 500
    medium:
      fileName: "#{originalName}._SL160_.#{ext}"
      width: "160"
    small:
      fileName: "#{originalName}._SL75_.#{ext}"
      width: "75"
  result


module.exports = {generateVariants, isOriginal}


if not module.parent
  console.log "teSt.jpg => ", JSON.stringify(template("teSt.jpg"), null, 2)
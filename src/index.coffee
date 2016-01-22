{Q, awsPromised, partial} = require './common'

rules = require './rules'
imageBuffer = require './image_buffer'

log = partial(console.log, "s3ImageHandler")

### s3 workflows ###
  
s3WorkflowPut = (fileName, bucketName, region) -> Q.genrun ->
  logger = partial(log, 's3WorkflowPut', "#{region}", "#{bucketName}")
  s3 = new awsPromised.s3({ region })
  
  logger "#{fileName} checking variants"
  
  # create a map of variants => filename, size
  variants = rules.generateVariants(fileName)
  
  buffer = false
  
  for variantName, variant of variants
    
    if not variant.width then continue
    
    try
      yield s3.headObjectPromised({ Bucket: bucketName, Key: variant.fileName })
      exists = true
    catch e
      exists = false
      
    if exists then continue
    
    logger "#{variant.fileName} missing, creating one"
    
    if not buffer
      
      response = yield s3.getObjectPromised({ Bucket: bucketName, Key: fileName })
      buffer = response.Body
    
    Body = yield imageBuffer.resize(buffer, fileName, variant.width)
    ACL = 'public-read'
    ContentType = 'image/jpeg'
    yield s3.putObjectPromised({ Bucket: bucketName, Key: variant.fileName, ACL, ContentType, Body })
    logger "#{variant.fileName} created"
  

s3WorkflowDelete = (fileName, bucketName, region) -> Q.genrun ->
  logger = partial(log, 's3WorkflowDelete', "#{region}", "#{bucketName}")
  s3 = new awsPromised.s3({ region })
  
  logger "#{fileName} checking variants"

  # create a map of variants => filename, size
  variants = rules.generateVariants(fileName)
  
  for variantName, variant of variants
    
    if not variant.width then continue
    
    # TODO: instead of using a head request first we may just try to delete it
    try
      yield s3.headObjectPromised({ Bucket: bucketName, Key: variant.fileName })
      exists = true
    catch e
      exists = false
      
    if not exists then continue
    
    response = yield s3.deleteObjectPromised({ Bucket: bucketName, Key: variant.fileName })
    logger "#{variant.fileName} deleted"

  
### amazon lambda handler ###

exports.handler = amazonLambdaHandler = (event, context) -> Q.genrun ->
  try
    # Apparently, a single "event" may include many s3 events
    for record in event.Records
      bucketName = record.s3.bucket.name;
      awsRegion = record.awsRegion
      eventName = record.eventName
      fileName = record.s3.object.key
      
      if rules.isNotAnOriginal(fileName)
        log "#{fileName} #{eventName}, skipping"
        continue
      
      if eventName.indexOf("ObjectCreated") != -1
        yield s3WorkflowPut(fileName, bucketName, awsRegion)
      if eventName.indexOf("ObjectRemoved") != -1
        yield s3WorkflowDelete(fileName, bucketName, awsRegion)
  
    context.succeed()
  catch e
    console.log e, e.stack.split('\n')
    context.fail()


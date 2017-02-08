{Q, awsPromised, partial, path} = require './common'

rules = require './rules'
imageBuffer = require './image_buffer'

log = partial(console.log, "s3ImageHandler")

### s3 workflows ###
  
s3WorkflowPut = (key, bucketName, region) -> Q.genrun ->
  logger = partial(log, 's3WorkflowPut', "#{region}", "#{bucketName}")
  before = Date.now()
  now = -> Date.now() - before

  s3 = new awsPromised.s3({ region })
  
  logger "#{key} checking variants [#{now()}]"
  
  variants = rules.generateVariants(key)
  
  buffer = false
  
  for variantName, variant of variants
    
    if not variant.width then continue
    
    try
      yield s3.headObjectPromised({ Bucket: bucketName, Key: variant.key})
      exists = true
    catch e
      exists = false
      
    if exists then continue
    
    logger "#{variant.key} missing, creating one [#{now()}]"
    
    if not buffer
      
      response = yield s3.getObjectPromised({ Bucket: bucketName, Key: key})
      buffer = response.Body
      logger "#{key} got data [#{now()}]"
  
    Body = yield imageBuffer.resize(buffer, variant.key, variant.width)
    ACL = 'public-read'
    ContentType = 'image/jpeg'
    yield s3.putObjectPromised({ Bucket: bucketName, Key: variant.key, ACL, ContentType, Body })
    logger "#{variant.key} created [#{now()}]"
  

s3WorkflowDelete = (key, bucketName, region) -> Q.genrun ->
  logger = partial(log, 's3WorkflowDelete', "#{region}", "#{bucketName}")
  before = Date.now()
  now = -> Date.now() - before
  
  s3 = new awsPromised.s3({ region })
  
  logger "#{key} checking variants [#{now()}]"

  variants = rules.generateVariants(key)
  
  for variantName, variant of variants
    if not variant.width then continue
    try
      response = yield s3.deleteObjectPromised({ Bucket: bucketName, Key: variant.key })
      logger "#{variant.key} deleted [#{now()}]"
    catch e

  
### amazon lambda handler ###

exports.handler = amazonLambdaHandler = (event, context) -> Q.genrun ->
  try
    # Apparently, a single "event" may include many s3 events
    for record in event.Records
      bucketName = record.s3.bucket.name;
      awsRegion = record.awsRegion
      eventName = record.eventName
      key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "))
      
      if key[key.length - 1] == '/'
        log "#{key} #{eventName}, skipping directories"
        continue
  
      if rules.isNotAnOriginal(key)
        log "#{key} #{eventName}, skipping variant"
        continue
      
      if eventName.indexOf("ObjectCreated") != -1
        yield s3WorkflowPut(key, bucketName, awsRegion)
      if eventName.indexOf("ObjectRemoved") != -1
        yield s3WorkflowDelete(key, bucketName, awsRegion)
  
    context.succeed()
  catch e
    console.log e, e.stack.split('\n')
    context.fail()


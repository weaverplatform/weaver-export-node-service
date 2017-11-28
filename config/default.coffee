module.exports =
  wes:
    port: 2525
    logging:
      console: 'info'
      file:    'error'
    
  services:
    excelMicroservice: 'http://localhost:9267'
    # excelMicroservice: 'http://docker.for.mac.localhost:9267'
 
  # weaver: 'http://docker.for.mac.localhost:9487'
  weaver: 'https://hawaii.weaverplatform.com'

  dataDir: "./data/"

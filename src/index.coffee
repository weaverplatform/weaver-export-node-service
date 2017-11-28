# Libs
express           = require('express')
app               = express()
http              = require('http').Server(app)
fs                = require('fs')
config            = require('config')
Weaver            = require('weaver-sdk')
WeaverConnect     = require('./WeaverConnect')
ExcelGen          = require('./ExcelGen')
logger            = require('./util/logger')



info = JSON.parse(fs.readFileSync('./package.json', 'utf8'))

# Setup
weaver = new Weaver()
try
  weaver.connect(config.get('weaver'))
catch error
  logger.error error
  

# Index page
app.get('/', (req, res) ->
  res.status(200).send("#{info.name} #{info.version}")
)

app.get('/+exceldump', (req, res) ->
  
  if !req.query.project?
    res.status(400).send("Query parameter 'project' is required")
    return

  project = req.query.project
  
  if !req.query.user?
    res.status(400).send("Query parameter user with 'authToken' is required")
    return

  authToken = req.query.user
  
  nameAttribute = if req.query.nameAttribute? then req.query.nameAttribute else null
  
  excelGen = new ExcelGen()
  
  
  weaverConnect = new WeaverConnect(weaver)
  weaverConnect.dumpQuery(authToken,project)
  .then((results) =>
    excelGen.getExcel(results,nameAttribute, res)
  ).catch((err) ->
    logger.error err
    res.status(400).send("Something went wrong during weaver querying")
  )
)

app.get('/+swagger', (req, res) ->
  res.sendFile('swagger.yaml', {root: './static/'})
)

# Run
port = process.env.PORT or config.get('wes.port')
http.listen(port, =>
  logger.info "#{info.name} #{info.version} running on port #{port}"
  logger.info "Connecting to weaver endpoint: #{config.get('weaver')}"
  return
)

rp      = require('request-promise')
Promise = require('bluebird')
config  = require('config')

cookies = rp.jar()

USERNAME = config.get('do.username')
PASSWORD = config.get('do.password')
BASEURL  = config.get('do.url')
PROVIDER = config.get('do.provider')
PAGESIZE = 100

login = ->
  rp({
    method: 'POST',
    uri: "#{BASEURL}/api/auth/#{PROVIDER}?UserName=#{encodeURIComponent(USERNAME)}&Password=#{encodeURIComponent(PASSWORD)}&format=json",
    jar: cookies
  }).then(->
    console.log "Succesfully logged in to #{BASEURL} with user #{USERNAME}"
  ).catch((err) ->
    console.error "Error logging in: #{err}"
    throw new Error("Unable to log on to the DigiOffice API")
  )

doRequest = (request, project, retryOnFail = true) ->
  uri = "#{BASEURL}/api/#{request}"
  console.log "Requesting: #{uri}"
  result = rp({
    method: 'GET'
    uri
    jar: cookies
    json: true
  })

  if retryOnFail
    result.catch((err) ->
      if(err.statusCode is 401)
        login().then(->
          doRequest(request, project, false)
        ).catch((err) ->
          Promise.reject("Error logging on to DigiOffice API")
        )
      else if (err.statusCode is 404)
        console.error "Not found on: #{request}"
        Promise.reject("Digioffice request #{request} was not found")
      else
        console.error "Error connecting to the DigiOffice API: #{err}"
        Promise.reject("DigiOffice API can't be reached")
    )
  else
    result

applicationInfo = ->
  doRequest("xml/reply/getapplicationinfo?format=json")

projectView = config.get('do.projectsView')
projectExplorers = {}
projectSBSExplorer = config.get('do.projectSBSExplorer')
projectDossiersExplorer = config.get('do.projectSBSExplorer')
projects = {}

setup = applicationInfo().then((info) ->
  console.log "Connected to digioffice environment #{info.Environment} version #{info.Version}"
  doRequest("documentviews/#{projectView}/explorers/#{projectSBSExplorer}/navigators?format=json")
).then((navigators) ->
  projects[i.Title] = i.Path for i in navigators
  console.log "Projects available:"
  console.log i for i of projects
)

scrape = (path, pageNumber = 1, total = []) ->
  urlForPage = "documents?format=json&pagesize=#{PAGESIZE}&pageNumber=#{pageNumber}&viewid=#{projectView}&explorerid=#{projectSBSExplorer}&path=#{path}"
  doRequest(urlForPage).then((documents) ->
    console.log "Page #{pageNumber} returned #{documents.length} documents, now have #{total.length}"
    total = total.concat(documents)

    if documents.length is PAGESIZE
      scrape(path, pageNumber+1, total)
    else
      total
  )


class DigiOfficeService
  constructor: (@digiOfficeProjectName) ->
    console.log "DigiOfficeService created for project #{@digiOfficeProjectName}"

  getAllDocuments: ->
    setup.then(=>
      scrape(projects[@digiOfficeProjectName])
    )

module.exports = DigiOfficeService

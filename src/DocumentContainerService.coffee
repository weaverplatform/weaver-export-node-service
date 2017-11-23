Weaver  = require('weaver-sdk')
Promise = require('bluebird')
config  = require('config')
fs      = require('fs')

DCError = require('./DCError')
DocumentContainer = require('./DocumentContainer')

loopTimeout  = config.get('fetchTimeout')
dataDir      = config.get('dataDir')
NUMBER_MATCH = /^([0-9]{4}-[0-9]{4})[ \_]*v(\S+)/

class DocumentContainerService
  constructor: (@digiOfficeService, @projectName, @weaver) ->
    @documentContainers = {}
    console.log "DocumentContainerService create for #{@projectName} with dataDir #{dataDir}"

  getAllDocumentContainers: ->
    (value for key, value of @documentContainers)

  startFetching: ->
    console.log "Iniating fetching setup with loopTimout #{loopTimeout}."
    if loopTimeout >= 0
      @_loopFetch()
    else
      @_fetch()

  clear: ->
    @documentContainers = {}

  link: (containerId, absId, authToken, project) ->
    _link = (absNodePromise, containerNodePromise) ->
      Promise.join(absNodePromise, containerNodePromise, (absNode, containerNode) ->
        absNode.relation('dc:containerLink').add(containerNode)
        absNode.save()
      )

    container = @getContainer(containerId)
    @weaver.signInWithToken(authToken).then(=>
      @weaver.useProject(new Weaver.Project(project, project))
      _link(
        Weaver.Node.load(absId).catch((err) ->
          Promise.reject(new DCError(DCError.NOT_FOUND_ABS, "ABS Node not found"))
        ),
        Weaver.Node.load(containerId).catch((err) ->
          if err.code is 101
            new Weaver.Node(containerId).save()
          else
            Promise.reject(new DCError(DCError.UNKNOWN, 'Unable to get or create document container node'))
        )
      )
    )

  getContainersForAbs: (abs, authToken, project) ->
    @weaver.signInWithToken(authToken).then(=>
      @weaver.useProject(new Weaver.Project(project, project))
      Weaver.Node.load(abs)
    ).then((absNode) =>
      links = absNode.relation('dc:containerLink').all()
      @documentContainers[i.nodeId] for i in links when @documentContainers[i.nodeId]?
    ).catch((err) ->
      if err.code is 101
        Promise.reject(new DCError(DCError.NOT_FOUND_ABS, "ABS Node not found"))
      else
        Promise.reject(new DCError(DCError.UNKNOWN, err))
    )

  getDocumentContainers: (sbs, query, authToken) ->
    if sbs?
      throw new Error("Not yet implemented")
    result = @getAllDocumentContainers()
    if query?
      query = query.toLowerCase()
      result = result.filter((document) ->
        document.title.toLowerCase().indexOf(query) >= 0 or document.containerNumber.toLowerCase().indexOf(query) >= 0
      )
    result

  convertToDocumentContainer: (document) ->
    match = NUMBER_MATCH.exec(document.Number)
    if match?
      new DocumentContainer(document.Title, document.RootDocumentID, match[1], match[2], document.ID)
    else
      throw new Error("Unable to process document #{JSON.stringify(document)}")

  writeToDisk: (file) ->
    fs.writeFile(file, JSON.stringify(@documentContainers))

  getContainer: (id) ->
    @documentContainers[id]

  storeDocumentContainer: (document) ->
    dc = @convertToDocumentContainer(document)
    existingContainer = @getContainer(dc.containerId)
    if existingContainer?
      existingContainer.merge(dc)
    else
      @documentContainers[dc.containerId] = dc

  _loopFetch: ->
    startAgain = () =>
      console.log "Starting fetch again in #{loopTimeout}"
      setTimeout(
        =>
          @_loopFetch()
        , loopTimeout
      )

    @_fetch().then( =>
      startAgain()
    ).catch( =>
      startAgain()
    )

  _fetch: ->
    console.log "Fetch started..."
    console.log @digiOfficeService
    @digiOfficeService.getAllDocuments().then((documents) =>
      for document in documents
        try
          @storeDocumentContainer(document)
        catch error
          console.error(error)
    ).then(=>
      @writeToDisk("#{dataDir}/#{@projectName}.json")
    )

module.exports = DocumentContainerService

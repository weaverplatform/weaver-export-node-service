Weaver  = require('weaver-sdk')
Promise = require('bluebird')
config  = require('config')
request = require('request')
fs      = require('fs')
logger  = require('./util/logger')

class ExcelGen
  
  constructor: ->
    @sheet = {0:{0:{}}}
    @headers = ['Node name','Node ID','Attribute key','Attribute value','Relation key','Target ID','Target Name']
    @excelMicroserviceEndpoint = config.get('services.excelMicroservice')
    @fileName = 'dump.xlsx'

  createHeaders: ->
    i = 0
    for head in  @headers
      @sheet[0][0]["#{i}"] = {value:head,type:'String'}
      i++
    Promise.resolve()
    
  createExcelReport: (sheet, response) ->
    try
      request.post({url:"#{@excelMicroserviceEndpoint}/excel/create?fileName=#{@fileName}",headers:{"content-type": "application/json"}, json: sheet}, (err, httpResponse, body) ->
        if err
          logger.error err
      ).pipe(response)
    catch error
      logger.error error
    
  processWeaverNodesForJSONExcel: (weaverNodes, nameAttribute = 'name') ->
    index = 1
    for node in weaverNodes
      sheetLines = Object.keys(@sheet[0]).length
      nodeName = if node.get(nameAttribute)? then node.get(nameAttribute) else '-'
      if node.attributes?
        for k,v of node.attributes
          for attribute in v
            i = 0
            @sheet[0][index] = {}
            @sheet[0][index][i++] = {value:nodeName, type:'String'}
            @sheet[0][index][i++] = {value:node.id(), type:'String'}
            @sheet[0][index][i++] = {value:attribute.key, type:'String'}
            @sheet[0][index][i++] = {value:attribute.value, type:'String'}
            @sheet[0][index][i++] = {value:'', type:'String'}
            @sheet[0][index][i++] = {value:'', type:'String'}
            @sheet[0][index][i++] = {value:'', type:'String'}
            index++
      if node.relations?
        for k,v of node.relations
          relationKey = v.key
          for ke,va of v.nodes
            i = 0
            @sheet[0][index] = {}
            nameRelation = if va.attributes[nameAttribute]? then va.attributes[nameAttribute][0].value else '-'
            @sheet[0][index][i++] = {value:nodeName, type:'String'}
            @sheet[0][index][i++] = {value:node.id(), type:'String'}
            @sheet[0][index][i++] = {value:'', type:'String'}
            @sheet[0][index][i++] = {value:'', type:'String'}
            @sheet[0][index][i++] = {value:relationKey, type:'String'}
            @sheet[0][index][i++] = {value:va.nodeId, type:'String'}
            @sheet[0][index][i++] = {value:nameRelation, type:'String'}
            index++
      if sheetLines isnt Object.keys(@sheet[0]).length
        index++
    Promise.resolve()
    
  getExcel: (weaverNodes, nameAttribute, response) ->
    @createHeaders()
    .then( =>
      @processWeaverNodesForJSONExcel(weaverNodes,nameAttribute)
    ).then( =>
      logger.debug JSON.stringify(@sheet)
      @createExcelReport(@sheet, response)
    )
  
module.exports = ExcelGen

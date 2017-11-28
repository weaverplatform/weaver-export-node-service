Weaver  = require('weaver-sdk')
Promise = require('bluebird')
config  = require('config')

class WeaverConnect
  
  constructor: (@weaver) ->
    
  ###
   Perfomrs a query to retrieve all the nodes
   right now it uses the query to retrieve all the nodes with relations out
  ###
    
  dumpQuery: (authToken, project) ->
    @weaver.signInWithToken(authToken)
    .then( =>
      @weaver.useProject(new Weaver.Project(project, project))
    ).then( =>
      new Weaver.Query().selectOut('*').find()
    ).then((results) =>
      results
    )
  
module.exports = WeaverConnect

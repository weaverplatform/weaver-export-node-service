class DocumentContainer
  constructor: (@title, @containerId, @containerNumber, versionNumber, documentId) ->
    @versions = [
      {
        versionNumber: versionNumber
        documentId:    documentId
      }
    ]

  merge: (otherContainer) ->
    @versions.push(i) for i in otherContainer.versions when i.versionNumber not in (j.versionNumber for j in @versions)

module.exports = DocumentContainer

require('./test-suite')

fs = require('fs')

DocumentContainerService = require('../src/DocumentContainerService')

describe 'The document container service', ->
  before ->
    @instance = new DocumentContainerService(undefined)
    @rawDocs = JSON.parse(fs.readFileSync('test/rijnlanddocs.json', 'utf8'))

  it 'should convert a single document to a container', ->
    result = @instance.convertToDocumentContainer(@rawDocs[0])
    expect(result).to.have.property('title')
    expect(result).to.have.property('containerId')
    expect(result).to.have.property('containerNumber')
    expect(result).to.have.property('versions')

  it 'should throw an error converting an unknown number format', ->
    expect(=> @instance.convertToDocumentContainer({
      Number: 'this is not right'
    })).to.throw('Unable to process document')

  it 'should convert a document without an underscore number', ->
    expect(@instance.convertToDocumentContainer({
      Number: '1234-1234 v1.0'
    })).to.have.property('containerNumber').be.equal('1234-1234')

  it 'should convert a document with an underscore number', ->
    expect(@instance.convertToDocumentContainer({
      Number: '1234-1234_ v1.0'
    })).to.have.property('containerNumber').be.equal('1234-1234')

  it 'should convert a document with a disconnected underscore number', ->
    expect(@instance.convertToDocumentContainer({
      Number: '1234-1234 _ v1.0'
    })).to.have.property('containerNumber').be.equal('1234-1234')

  it 'should be able to convert all rijnlanddocs', ->
    expect(Promise.all(@instance.convertToDocumentContainer(i) for i in @rawDocs)).to.not.throw

  describe 'clearing between each test', ->
    afterEach ->
      @instance.clear()

    it 'should make stored document containers available', ->
      @instance.storeDocumentContainer({
        Number: '1234-1234 v2.0'
        RootDocumentID: '1234'
        Title: "A very testy document"
      })
      expect(@instance.getAllDocumentContainers()).to.have.length.be(1)

    it 'should make multiple document containers available', ->
      @instance.storeDocumentContainer({
        Number: '1234-1234 v2.0'
        RootDocumentID: '1234'
        Title: "A very testy document"
      })
      @instance.storeDocumentContainer({
        Number: '0000-0000 v1.0'
        RootDocumentID: 'kcvikskd'
        Title: "Another test document"
      })
      expect(@instance.getAllDocumentContainers()).to.have.length.be(2)

    it 'should merge multiple documents with the same root document id', ->
      @instance.storeDocumentContainer({
        Number: '1234-1234 v2.0'
        RootDocumentID: '1234'
        ID: '2222'
        Title: "A very testy document"
      })
      @instance.storeDocumentContainer({
        Number: '1234-1234 v1.2'
        RootDocumentID: '1234'
        ID: '1111'
        Title: "A very testy document"
      })
      res = @instance.getAllDocumentContainers()
      expect(res).to.have.length.be(1)
      expect(res[0]).to.have.property('versions').to.have.property('1.2').to.equal('1111')
      expect(res[0]).to.have.property('versions').to.have.property('2.0').to.equal('2222')

  describe 'with a bunch of documents', ->
    before ->
      @instance.storeDocumentContainer({
        Number: '1234-1234 v2.0'
        RootDocumentID: '1234'
        ID: '2222'
        Title: "A very testy document"
      })
      @instance.storeDocumentContainer({
        Number: '1234-1234 v1.2'
        RootDocumentID: '1234'
        ID: '1111'
        Title: "A very testy document"
      })
      @instance.storeDocumentContainer({
        Number: '1123-1234 _ v3.0'
        RootDocumentID: '1333'
        ID: '1234'
        Title: "Something completely different"
      })

    it 'should have the correct count', ->
      expect(@instance.getAllDocumentContainers()).to.have.length.be(2)

    it 'should still have the correct count', ->
      expect(@instance.getAllDocumentContainers()).to.have.length.be(2)

    it 'should be able to write the state to disk', ->
      expect(@instance).to.have.property('writeToDisk')
      expect(@instance.writeToDisk('test.json')).to.not.throw
      fs.unlink('test.json')

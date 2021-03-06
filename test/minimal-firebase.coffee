
###
# jsom 3.x documentation: http://bit.ly/1OROksU
###

# dependencies
expect = require 'expect.js'
fs = require 'fs'
jsdom = require 'jsdom'

# locals
FB_ROOT = 'https://minimal-firebase.firebaseio.com'
firebase = null
window = null

# tests
describe 'Minimal Firebase', ->

  # setup jsdom
  before (done) ->
    jsdom.env {
      html: '<html><body></body></html>'
      src: [
        fs.readFileSync './build/minimal-firebase.js', 'utf-8'
      ]
      done: (err, _window) ->
        window = _window
        jsdom.getVirtualConsole(window).sendTo console
        done()
  }

  describe 'setup', ->

    it 'is defined', ->
      expect(window.MinimalFirebase).to.be.ok()

    it 'can be constructed', ->
      firebase = new window.MinimalFirebase FB_ROOT
      expect(firebase).to.be.ok()

    it 'should crash if the input url is not a firebase url', ->
      fn = window.MinimalFirebase
      url = 'https://google.com'
      expect(fn).withArgs(url).to.throwError()

    it 'should trim trailing slashes from the url', ->
      ref = new window.MinimalFirebase "#{FB_ROOT}/"
      expect(ref.url).to.equal FB_ROOT

  describe 'database traversal', ->

    it 'should be able to get the root firebase url', ->
      ref = firebase.child 'test'
      expect(ref.root()).to.equal FB_ROOT

    it 'should be able to get a child ref', ->
      path = 'testing/1/2/3'
      ref = firebase.child path
      expect(ref.toString()).to.equal "#{FB_ROOT}/#{path}"

    it 'should be able to get a child ref with period', ->
      ref = firebase.child 'testing.1.2.3'
      expect(ref.toString()).to.equal "#{FB_ROOT}/testing/1/2/3"

    it 'should be able to get the parent ref', ->
      ref = firebase.child 'a/b/c'
      parent = ref.parent()
      expect(parent.url).to.equal "#{FB_ROOT}/a/b"

    it 'should have a null parent on the root ref', ->
      ref = firebase.parent()
      expect(ref).to.equal null

  describe 'ref properties', ->

    it 'should have a toString() equal to the path', ->
      ref = firebase.child 'test'
      expect(firebase.toString()).to.equal firebase.url
      expect(ref.toString()).to.equal ref.url

    it 'should be able to get the key of the ref', ->
      ref = firebase.child 'a/b/c'
      expect(ref.key()).to.equal 'c'
      expect(firebase.key()).to.equal null

  describe 'loading data', ->

    it 'should be able to get data (numbers)', (done) ->
      ref = firebase.child 'test/number'
      ref.once (err, value) ->
        expect(err).to.equal null
        expect(typeof value).to.equal 'number'
        expect(value).to.equal 42
        done()

    it 'should be able to get data (strings)', (done) ->
      ref = firebase.child 'test/string'
      ref.once (err, value) ->
        expect(err).to.equal null
        expect(typeof value).to.equal 'string'
        expect(value).to.equal 'hello world'
        done()

    it 'should be able to get data (objects)', (done) ->
      ref = firebase.child 'test/object'
      ref.once (err, value) ->
        expect(err).to.equal null
        expect(typeof value).to.equal 'object'
        expect(value).to.eql {foo: 'bar'}
        done()

    it 'should be able to get data (arrays)', (done) ->
      ref = firebase.child 'test/array'
      ref.once (err, value) ->
        expect(err).to.equal null
        expect(Array.isArray value).to.equal true
        expect(value.toString()).to.equal "1,2,3"
        done()

    it 'should be able to get shallow data', (done) ->
      ref = firebase.child 'test/shallow'
      ref.once {shallow: true}, (err, value) ->
        expect(err).to.equal null
        expect(value).to.eql {x: true, y: true}
        done()

    it 'should be able to get export data', (done) ->
      ref = firebase.child 'test/shallow'
      ref.once {format: 'export'}, (err, value) ->
        expect(err).to.equal null
        expect(value).to.eql {x: 'hello', y: 'world'}
        done()

    it 'should be able to get data synchronously', ->
      ref = firebase.child 'test/number'
      value = ref.once()
      expect(typeof value).to.equal 'number'
      expect(value).to.equal 42

  describe 'advanced queries', ->

    it 'should be able to order by key', (done) ->
      ref = firebase.child 'test/dataset_1'
      ref.once {orderBy: '$key', equalTo: 'cat'}, (err, value) ->
        expect(value.cat.title).to.equal 'Cat'
        done()

    it 'should be able to filter on a string', (done) ->
      ref = firebase.child 'test/dataset_1'
      ref.once {orderBy: 'title', equalTo: 'Cat'}, (err, value) ->
        expect(value.cat.title).to.equal 'Cat'
        done()

    it 'should be able to filter on a number', (done) ->
      ref = firebase.child 'test/dataset_1'
      ref.once {orderBy: 'legs', equalTo: 4}, (err, value) ->
        animals = (v for k, v of value)
        expect(animals.length).to.equal 3
        done()

  describe 'authentication', ->

    it 'should be able to auth anonymously', (done) ->
      firebase.authAnonymously (err, user) ->
        expect(err).to.equal null
        expect(user.provider).to.equal 'anonymous'
        done()

    it 'should be able to create a new user', (done) ->
      email = "user_#{Date.now()}@test.com"
      password = "hello world #{Math.random()}"
      firebase.createUser email, password, (err, user) ->
        expect(err).to.equal null
        expect(user).to.have.property 'uid'
        done()

    it 'should fail trying to create an existing user', (done) ->
      email = 'hello@test.com'
      password = 'world'
      firebase.createUser email, password, (err, user) ->
        expect(err?.code).to.equal 'EMAIL_TAKEN'
        done()

    it 'should be able to auth with password', (done) ->
      email = 'hello@test.com'
      password = 'world'
      firebase.authWithPassword email, password, (err, user) ->
        expect(err).to.equal null
        expect(user.uid).to.equal '7abe39b4-aeee-4c29-9030-ecfff48be677'
        done()

    it 'should catch invalid password for auth with password', (done) ->
      email = 'hello@test.com'
      password = 'invalid'
      firebase.authWithPassword email, password, (err, user) ->
        expect(err?.code).to.equal 'INVALID_PASSWORD'
        done()

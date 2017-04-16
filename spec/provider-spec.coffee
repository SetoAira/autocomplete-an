describe 'AIRNovel property name and value autocompletions', ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-an')
    waitsForPromise -> atom.packages.activatePackage('language-an')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-an').mainModule.getProvider()

    waitsFor -> Object.keys(provider.completions).length > 0

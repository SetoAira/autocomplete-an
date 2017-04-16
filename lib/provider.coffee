path = require 'path'
COMPLETIONS = require('../completions.json')

firstAttrName = /\[\S+\s(\S+)=/ #[lay layer=
attrName = /(?:\S+=.+?\s)*(\S+)=/ #[lay layer=mes fn=
firstBeforeConstant = /(?:'|"|&|=|\s)((?:mp:|save:|sys:)?(?:const\.an)?\w*)\.$/ # text=sys:const.
beforeConstant = /(?:'|"|&|=|\s)(?:mp:|save:|sys:)?(?:\w+?\.)*(\w+)\.$/ # text=const.
layoutPattern = /.*layout=(?:#&)?'(?:\w+=".+?" )*(?:\w+=")?$/ #layout=

module.exports =
  selector: '.source.airnovel'
  disableForSelector: '.source.airnovel .comment'
  suggestionPriority: -1
  filterSuggestions: true

  tags: COMPLETIONS.tag
  attrs: COMPLETIONS.attr
  constants: COMPLETIONS.constant
  layouts: COMPLETIONS.layout

  getSuggestions: (request) ->
    completions = null
    lastSymbol = @getLastSymbol(request)

    if lastSymbol is '.'
      completions = @getConstantNextCompletions(request)
    else if @isInLayout(request)
      completions = @getLayoutCompletions(request)
    else if lastSymbol is '='
      completions = @getValueCompletions(request)
    else if lastSymbol is '['
      completions = @getTagCompletions(request)
    else if lastSymbol is ' '
      completions = @getCompletion(request)
    else
      completions = @getConstantsCompletions(request)

    completions

  getConstantNextCompletions: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    constant = @getPreviousConstantName(bufferPosition, editor)
    values = @constants[constant]?.next
    return null unless values?

    completions = []
    for value in values
      if value.indexOf("$") is -1
        completions.push({type: 'constant', text: value})
      else
        completions.push({type: 'constant', snippet: value})

    completions

  getLayoutCompletions: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    if prefix.length < 2
      return null

    completions = []
    for value in @layouts
      completions.push({type: 'layout', text: value})

    completions

  getValueCompletions: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    completions = []
    if prefix.length >= 2
      for value of @constants
        completions.push({type: 'constant', text: value})

    preAttr = @getPreviousAttr(bufferPosition, editor)
    values = @attrs[preAttr]?.value
    return completions unless values?

    for value in values
      completions.push({type: 'value', text: value})

    completions

  getTagCompletions: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    completions = []

    for value in @tags
      if value.indexOf("$") is -1
        completions.push({type: 'tag', text: value})
      else
        completions.push({type: 'tag', snippet: value})

    completions

  getCompletion: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    if prefix.length < 2
      return null

    completions = []
    for value of @attrs
      completions.push({type: 'attr', text: value})
    for value of @constants
      completions.push({type: 'constant', text: value})

    completions

  getConstantsCompletions: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    if prefix.length < 2
      return null

    completions = []
    for value of @constants
      completions.push({type: 'constant', text: value})

    completions


  getPreviousConstantName: (bufferPosition, editor) ->
    {row, column} = bufferPosition
    line = editor.lineTextForBufferRow(row)
    line = line.substr(0, column)
    constantName = firstBeforeConstant.exec(line)?[1]
    constantName ?= beforeConstant.exec(line)?[1]
    return constantName if constantName
    return

  getPreviousAttr: (bufferPosition, editor) ->
    {row, column} = bufferPosition
    line = editor.lineTextForBufferRow(row)
    line = line.substr(0, column)
    preAttrName = attrName.exec(line)?[1]
    preAttrName ?= firstAttrName.exec(line)?[1]
    return preAttrName if preAttrName
    return

  isInLayout: ({scopeDescriptor, bufferPosition, prefix, editor}) ->
    {row, column} = bufferPosition
    line = editor.lineTextForBufferRow(row)
    line = line.substr(0, column - prefix.length)

    layoutPattern.exec(line) isnt null

  getLastSymbol: ({scopeDescriptor, bufferPosition, prefix, editor}) ->
    {row, column} = bufferPosition
    line = editor.lineTextForBufferRow(row)
    req = /\W|\./
    i = 1
    while i <= column
      lastchar = line.charAt(column - i)
      return lastchar if req.exec(lastchar)
      i++
    return

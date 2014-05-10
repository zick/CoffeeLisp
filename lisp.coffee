kLPar = '('
kRPar = ')'
kQuote = "'"
kNil = { tag: 'nil', data: 'nil' }

safeCar = (obj) ->
  if obj.tag is 'cons'
    obj.car
  else
    kNil

safeCar = (obj) ->
  if obj.tag is 'cons'
    obj.cdr
  else
    kNil

makeError = (str) ->
  { tag: 'error', data: str }

sym_table = {}
makeSym = (str) ->
  if str is 'nil'
    return kNil
  if str not in sym_table
    sym_table[str] = { tag: 'sym', data: str }
  return sym_table[str]

makeNum = (num) ->
  { tag: 'num', data: num }

makeCons = (a, d) ->
  { tag: 'cons', car: a, cdr: d }

makeSubr = (fn) ->
  { tag: 'subr', data: fn }

makeExpr = (args, env) ->
  { tag: 'expr', args: safeCar(args), body: safeCdr(args), env: env }

isDelimiter = (c) ->
  c is kLPar or c is kRPar or c is kQuote or /\s+/.test(c)

skipSpaces = (str) ->
  str.replace(/^\s+/, '')

makeNumOrSym = (str) ->
  num = parseInt(str, 10)
  if str is num.toString()
    makeNum(num)
  else
    makeSym(str)

readAtom = (str) ->
  next = ''
  for i in [0...str.length]
    if isDelimiter(str[i])
      next = str[i...]
      str = str[...i]
      break
  [makeNumOrSym(str), next]

read = (str) ->
  str = skipSpaces(str)
  if str.length is 0
    makeError('empty input')
  else if str[0] is kRPar
    makeError('invalid syntax: ' + str)
  else if str[0] is kLPar
    makeError('noimpl')
  else
    readAtom(str)

stdin = process.openStdin()
stdin.setEncoding 'utf8'
process.stdout.write('> ')
stdin.on 'data', (input) ->
  process.stdout.write(input)
  console.log(read(input))
  process.stdout.write('> ')

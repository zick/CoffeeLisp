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
  if not sym_table[str]
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

nreverse = (lst) ->
  ret = kNil
  while lst.tag is 'cons'
    tmp = lst.cdr
    lst.cdr = ret
    ret = lst
    lst = tmp
  ret

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
    readList(str[1...])
  else if str[0] is kQuote
    [elm, next] = read(str[1...])
    [makeCons(makeSym('quote'), makeCons(elm, kNil)), next]
  else
    readAtom(str)

readList = (str) ->
  ret = kNil
  while true
    str = skipSpaces(str)
    if str.length is 0
      return [makeError('unfinished parenthesis'), '']
    else if str[0] is kRPar
      break
    [elm, next] = read(str)
    if elm.tag is 'error'
      return [elm, '']
    ret = makeCons(elm, ret)
    str = next
  [nreverse(ret), str[1...]]

printObj = (obj) ->
  if obj.tag is 'num' or obj.tag is 'sym' or obj.tag is 'nil'
    obj.data.toString()
  else if obj.tag is 'error'
    '<error: ' + obj.data + '>'
  else if obj.tag is 'cons'
    printList(obj)
  else if obj.tag is 'subr' or obj.tag is 'expr'
    '<' + obj.tag + '>'
  else
    '<unknown>'

printList = (obj) ->
  ret = ''
  first = true
  while obj.tag is 'cons'
    if first
      first = false
    else
      ret += ' '
    ret += printObj(obj.car)
    obj = obj.cdr
  if obj.tag is 'nil'
    '(' + ret + ')'
  else
    '(' + ret + ' . ' + printObj(obj) + ')'

findVar = (sym, env) ->
  while env.tag is 'cons'
    alist = env.car
    while alist.tag is 'cons'
      if alist.car.car is sym
        return alist.car
      alist = alist.cdr
    env = env.cdr
  kNil

g_env = makeCons(kNil, kNil)

addToEnv = (sym, val, env) ->
  env.car = makeCons(makeCons(sym, val), env.car)

eval1 = (obj, env) ->
  if obj.tag is 'nil' or obj.tag is 'num' or obj.tag is 'error'
    return obj
  else if obj.tag is 'sym'
    bind = findVar(obj, env)
    if bind is kNil
      return makeError(obj.data + ' has no value')
    return bind.cdr
  makeError('noimpl')

addToEnv(makeSym('t'), makeSym('t'), g_env)

stdin = process.openStdin()
stdin.setEncoding 'utf8'
process.stdout.write('> ')
stdin.on 'data', (input) ->
  console.log(printObj(eval1(read(input)[0], g_env)))
  process.stdout.write('> ')

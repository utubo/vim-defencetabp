vim9script

# Game {{{
const WIDTH = 19
const INTERVAL = 150
var height = &lines
var screen = ''
var chars: list<dict<any>> = []
var timer = 0
var dx = -1
var waitcount = 0
var winid = 0
var cooltime = 0

def SetupScreen()
  height = &lines - &cmdheight - tabpagenr('$')
enddef

def Rendar()
  SetupScreen()
  var s = [' '->repeat(WIDTH)]->repeat(height)
  for c in chars
    if c.x <= WIDTH && c.y < height
      s[c.y] = s[c.y]->substitute($'\%{c.x}c.', c.char, '')
    endif
  endfor
  screen = ([''] + s)->join("\n%#TabPanel#")
enddef

const TABPANEL_EXPR = '%!defencetabp#TabPanel()'
var tabpanel_org = ''
var tabpanelopt_org = ''

export def Start()
  if tabpanel_org !=# TABPANEL_EXPR
    tabpanel_org = &tabpanel
    tabpanelopt_org = &tabpanelopt
  endif
  Init()
  Rendar()
  tabnext $
  &tabpanel = TABPANEL_EXPR
  if &tabpanelopt->match('columns:') ==# -1
    &tabpanelopt ..= $',columns:{WIDTH}'
  else
    &tabpanelopt = &tabpanelopt
      ->substitute('columns:\d\+', $'columns:{WIDTH}', '')
  endif
  set showtabpanel=2
  winid = popup_create('', {
    tabpage: -1,
    col: &columns,
    line: &lines,
    highlight: 'MsgArea',
    mapping: false,
    filter: OnKeyDown,
  })
  if !!timer
    timer_stop(timer)
  endif
  timer = timer_start(INTERVAL, Main, { repeat: -1 })
enddef

def Init()
  SetupScreen()
  chars = []
  # Player
  chars->add({
    char: 'V',
    x: 10,
    y: 0,
  })
  # Enemy
  for y in range(height - 3, height - 1)
    for x in range(5)
      chars->add({
        char: 'A',
        x: x * 3 + 5,
        y: y,
      })
    endfor
  endfor
  # Shield
  for y in range(3, 5)
    for x in range(1, WIDTH)
      chars->add({
        char: '-',
        x: x,
        y: y,
      })
    endfor
  endfor
enddef

def Close()
  if !!timer
    timer_stop(timer)
    timer = 0
  endif
  if !!winid
    popup_close(winid)
    winid = 0
  endif
  &tabpanel = tabpanel_org
  &tabpanelopt = tabpanelopt_org
  redrawtabp
enddef

def Main(_: number)
  if popup_list()->index(winid) ==# -1
    winid = 0
    Close()
  endif
  cooltime -= !!cooltime ? 1 : 0
  Move()
  Rendar()
  redrawtabp
enddef

def OnKeyDown(id: number, k: string): bool
  if chars[0].char ==# ' '
    if !cooltime
      chars[0].char = '.'
    endif
  elseif chars[0].char !=# 'V'
  # NOP
  elseif k ==# 'h'
    chars[0].x -= chars[0].x <= 1 ? 0 : 1
  elseif k ==# 'l'
    chars[0].x += chars[0].x < WIDTH ? 1 : 0
  elseif k ==# "\<Space>" && !cooltime
    chars->add({
      char: '|',
      x: chars[0].x,
      y: chars[0].y + 1,
      dy: 1,
    })
    cooltime = 3
  elseif k ==# "\<Esc>" || k ==# 'q'
    Close()
  endif
  Rendar()
  redrawtabp
  return true
enddef

def Move()
  SetupScreen()
  var dy = 0
  if !waitcount
    if dx < 0 && chars->indexof((_, v) => v.char ==# 'A' && v.x ==# 1) !=# -1
      dx = 1
    elseif 0 < dx && chars->indexof((_, v) => v.char ==# 'A' && v.x ==# WIDTH) !=# -1
      dx = -1
      dy = -1
    endif
  endif
  var removes = []
  var newchars = []
  for i in range(chars->len())
    var c = chars[i]
    if c.char ==# 'A'
      if !waitcount
        c.x += dx
        c.y += dy
        if dy ==# 0 &&
            rand() % 8 ==# 0 &&
            chars->indexof((_, v) =>
              v.char ==# 'A' &&
              v.x ==# c.x &&
              v.y < c.y
            ) ==# -1
          newchars->add({
            char: ':',
            x: c.x,
            y: c.y - 1,
            dy: -1,
          })
        endif
      endif
    elseif c.char ==# '|' || c.char ==# ':'
      c.y += c.dy
      const j = chars->indexof((_, v) => v.x ==# c.x && v.y ==# c.y)
      if j !=# -1 && i !=# j
        const isA = chars[j].char ==# 'A'
        chars[j] = {
          char: '+',
          x: chars[j].x,
          y: chars[j].y,
          dy: 0,
        }
        removes->add(i)
        if isA && chars->indexof((_, v) => v.char ==# 'A') ==# -1
          for x in range(10)
            chars->add({
              char: '= Clear! ='[x],
              x: x + 6,
              y: height / 2,
            })
          endfor
        endif
      endif
    elseif c.char ==# '*'
      if !i
        c.char = ' '
        cooltime = 5
      else
        removes->add(i)
      endif
    elseif c.char ==# '+'
      c.char = '*'
    elseif c.char ==# '.'
      c.char = 'v'
    elseif c.char ==# 'v'
      c.char = 'V'
    endif
    if c.y < 0
      removes->add(i)
      if tabpagenr('$') ==# 1
        GameOver()
      else
        confirm tabclose $
      endif
    endif
    if height < c.y
      removes->add(i)
    endif
  endfor
  for i in removes->reverse()
    chars->remove(i)
  endfor
  chars += newchars
  if !waitcount
    waitcount = 3
  else
    waitcount -= 1
  endif
enddef

def GameOver()
  for x in range(13)
    chars->add({
      char: '= Game Over ='[x],
      x: x + 4,
      y: height / 2,
    })
  endfor
  Rendar()
  redrawtabp
  confirm quit
enddef
# }}}

# TabPanel {{{
def SimpleTabLabel(): string
  const bufs = tabpagebuflist(g:actual_curtabpage)
  var mod = ''
  for bufnr in bufs
    if getbufvar(bufnr, "&modified")
      mod = '+'
      break
    endif
  endfor
  const wincount_num = tabpagewinnr(g:actual_curtabpage, '$')
  const wincount = wincount_num < 2 ? '' : $'{wincount_num}'
  const name = bufs[tabpagewinnr(g:actual_curtabpage) - 1]->bufname()
  const sep = !wincount && !mod ? '' : ' '
  const width = &tabpanelopt
    ->matchstr('\(columns:\)\@<=\d\+') ?? '20'
  return $'{wincount}{mod}{sep}{name ?? '[No Name]'}'
    ->substitute($'\%{width->str2nr()}v.*', '', '')
enddef

export def TabPanel(): string
  const label = SimpleTabLabel()
  const tabcount =  tabpagenr('$')
  if g:actual_curtabpage !=# tabcount
    return label
  endif
  return label .. screen
enddef
# }}}

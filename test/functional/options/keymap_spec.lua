local helpers = require('test.functional.helpers')(after_each)
local clear, feed, eq = helpers.clear, helpers.feed, helpers.eq
local expect, command, eval = helpers.expect,  helpers.command,  helpers.eval
local insert, call = helpers.insert, helpers.call
local funcs, dedent = helpers.funcs, helpers.dedent

-- First test it's implemented using the :lmap and :lnoremap commands, then
-- check those mappings behave as expected.
describe("'keymap' / :lmap", function()
  clear()
  before_each(function()
    clear()
    insert("lllaaa")
    command('set iminsert=1')
    command('set imsearch=1')
    command('lmap l a')
    feed('gg0')
  end)

  describe("'keymap' as :lmap", function()
    -- Shows that 'keymap' sets language mappings that allows remapping.
    -- This equivalence allows us to only test :lmap commands and assert they
    -- behave the same as 'keymap' settings.
    -- It does rely on the absence of special code that implements 'keymap'
    -- and :lmap differently but shows mappings from the 'keymap' after
    -- typing :lmap.
    -- At the moment this is the case.
    it("'keymap' mappings are shown with :lmap", function()
      command('lmapclear')
      command('lmapclear <buffer>')
      command('set keymap=dvorak')
      command('set nomore')
      local bindings = funcs.nvim_command_output('lmap')
      eq(dedent([[

      l  "            @_
      l  '            @-
      l  +            @}
      l  ,            @w
      l  -            @[
      l  .            @v
      l  /            @z
      l  :            @S
      l  ;            @s
      l  <            @W
      l  =            @]
      l  >            @V
      l  ?            @Z
      l  A            @A
      l  B            @X
      l  C            @J
      l  D            @E
      l  E            @>
      l  F            @U
      l  G            @I
      l  H            @D
      l  I            @C
      l  J            @H
      l  K            @T
      l  L            @N
      l  M            @M
      l  N            @B
      l  O            @R
      l  P            @L
      l  Q            @"
      l  R            @P
      l  S            @O
      l  T            @Y
      l  U            @G
      l  V            @K
      l  W            @<
      l  X            @Q
      l  Y            @F
      l  Z            @:
      l  [            @/
      l  \            @\
      l  ]            @=
      l  _            @{
      l  a            @a
      l  b            @x
      l  c            @j
      l  d            @e
      l  e            @.
      l  f            @u
      l  g            @i
      l  h            @d
      l  i            @c
      l  j            @h
      l  k            @t
      l  l            @n
      l  m            @m
      l  n            @b
      l  o            @r
      l  p            @l
      l  q            @'
      l  r            @p
      l  s            @o
      l  t            @y
      l  u            @g
      l  v            @k
      l  w            @,
      l  x            @q
      l  y            @f
      l  z            @;
      l  {            @?
      l  |            @|
      l  }            @+]]), bindings)
    end)
  end)
  describe("'iminsert' option", function()
    it("Uses :lmap in insert mode when ON", function()
      feed('il<esc>')
      expect('alllaaa')
    end)
    it("Ignores :lmap in insert mode when OFF", function()
      command('set iminsert=0')
      feed('il<esc>')
      expect('llllaaa')
    end)
    it("Can be toggled with <C-^> in insert mode", function()
      feed('i<C-^>l<C-^>l<esc>')
      expect('lalllaaa')
      eq(eval('&iminsert'), 1)
      feed('i<C-^><esc>')
      eq(eval('&iminsert'), 0)
    end)
  end)
  describe("'imsearch' option", function()
    it("Uses :lmap at search prompt when ON", function()
      feed('/lll<cr>3x')
      expect('lll')
    end)
    it("Ignores :lmap at search prompt when OFF", function()
      command('set imsearch=0')
      feed('gg/lll<cr>3x')
      expect('aaa')
    end)
    it("Can be toggled with C-^", function()
      eq(eval('&imsearch'), 1)
      feed('/<C-^>lll<cr>3x')
      expect('aaa')
      eq(eval('&imsearch'), 0)
      feed('u0/<C-^>lll<cr>3x')
      expect('lll')
      eq(eval('&imsearch'), 1)
    end)
    it("can follow 'iminsert'", function()
      command('set imsearch=-1')
      feed('/lll<cr>3x')
      expect('lll')
      eq(eval('&imsearch'), -1)
      eq(eval('&iminsert'), 1)
      feed('u/<C-^>lll<cr>3x')
      expect('aaa')
      eq(eval('&imsearch'), -1)
      eq(eval('&iminsert'), 0)
    end)
  end)
  it(":lmap not applied to macros", function()
    command("call setreg('a', 'il')")
    feed('@a')
    expect('llllaaa')
    eq(call('getreg', 'a'), 'il')
  end)
  it(":lmap applied to macro recording", function()
    feed('qail<esc>q@a')
    expect('aalllaaa')
    eq(call('getreg', 'a'), 'ia')
  end)
  it(":lmap not applied to mappings", function()
    command('imap t l')
    feed('it<esc>')
    expect('llllaaa')
  end)
  it("mappings applied to keys created with :lmap", function()
    command('imap a x')
    feed('il<esc>')
    expect('xlllaaa')
  end)
  it("mappings not applied to keys gotten with :lnoremap", function()
    command('lmapclear')
    command('lnoremap l a')
    command('imap a x')
    feed('il<esc>')
    expect('alllaaa')
  end)
  -- This is a problem introduced when introducting :lmap and macro
  -- compatibility. There are no plans to fix this as the complexity involved
  -- seems too great.
  pending('mappings not applied to macro replay of :lnoremap', function()
    command('lmapclear')
    command('lnoremap l a')
    command('imap a x')
    feed('qail<esc>q')
    expect('alllaaa')
    feed('@a')
    expect('aalllaaa')
  end)
  it("is applied when using f/F t/T", function()
    feed('flx')
    expect('lllaa')
    feed('0ia<esc>4lFlx')
    expect('lllaa')
    feed('tllx')
    expect('llla')
    feed('0ia<esc>4lTlhx')
    expect('llla')
  end)
  it('takes priority over :imap mappings', function()
    command('imap l x')
    feed('il<esc>')
    expect('alllaaa')
    command('lmapclear')
    command('lmap l a')
    feed('il')
    expect('aalllaaa')
  end)
end)

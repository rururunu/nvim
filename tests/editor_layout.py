"""Use Neovim's real UI protocol to exercise focus/layout, without touching the user's editor."""
import os, sys, subprocess, threading, queue, time, tempfile
sys.path.insert(0, os.path.join(tempfile.gettempdir(), 'nvim-rpc-deps'))
import msgpack
p = subprocess.Popen(['nvim', '--embed', '-n', '-i', 'NONE'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
responses = queue.Queue(); events=[]
def reader():
    u=msgpack.Unpacker(raw=False, strict_map_key=False)
    while True:
        data=os.read(p.stdout.fileno(),65536)
        if not data: break
        u.feed(data)
        for m in u:
            if m[0]==1: responses.put(m)
            elif m[0]==2: events.append(m)
threading.Thread(target=reader, daemon=True).start()
seq=0
def request(method,args):
    global seq
    seq+=1; p.stdin.write(msgpack.packb([0,seq,method,args],use_bin_type=True));p.stdin.flush()
    end=time.time()+30
    while time.time()<end:
        m=responses.get(timeout=30)
        if m[1]==seq:
            if m[2]: raise RuntimeError(m[2])
            return m[3]
    raise RuntimeError('request timed out')
def lua(s): return request('nvim_exec_lua',[s,[]])

try:
 request('nvim_ui_attach',[100,30,{'rgb':True,'ext_linegrid':True}]);time.sleep(.7)
 lua("vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'});vim.cmd('enew');vim.bo.swapfile=false;vim.api.nvim_buf_set_name(0,'layout-inspect.lua');vim.api.nvim_buf_set_lines(0,0,-1,false,{'FIRST_LINE','SECOND_LINE','THIRD_LINE'});require('config.editor_card').refresh();vim.cmd('redraw!')")
 time.sleep(.4)

 grid=[[' ']*100 for _ in range(30)]
 attrs=[[0]*100 for _ in range(30)]
 highlights={} 
 for m in events:
  if m[1]!='redraw':continue
  for ev in m[2]:
   if ev[0]=='hl_attr_define':
    for entry in ev[1:]:highlights[entry[0]]=entry[1]
   if ev[0]!='grid_line':continue
   for args in ev[1:]:
    g,r,c,cells,*_=args
    if g!=1:continue
    hl=0
    for cell in cells:
     if len(cell)>1:hl=cell[1]
     text=cell[0];repeat=cell[2] if len(cell)>2 else 1
     for j in range(repeat):
      if 0<=r<30 and 0<=c<100:
       grid[r][c]=text;attrs[r][c]=hl
      c+=1
 rows=[''.join(row) for row in grid]
 assert rows[0].startswith('╭') and rows[0].endswith('╮'), rows[0]
 assert '▎' in rows[1], 'selected tab marker missing'
 assert any(highlights.get(h,{}).get('background')==0x5fd7ff for h in attrs[1]), 'selected tab color not rendered'
 assert highlights.get(attrs[0][0],{}).get('foreground')==0x5fd7ff, 'focused border color not rendered'
 assert 'layout-inspect.lua' in rows[1] and 'FIRST_LINE' not in rows[1], rows[1]
 assert any('FIRST_LINE' in row for row in rows[2:-2]), 'first source line obscured'
 assert rows[-2].startswith('╰') and rows[-2].endswith('╯'), rows[-2]
 assert 'layout-inspect.lua' in rows[-1] and '1:1' in rows[-1], rows[-1]
 lua("local w=vim.api.nvim_get_current_win();local c=require('config.editor_card').cards[w];assert(vim.api.nvim_win_get_config(w).relative=='');assert(vim.api.nvim_win_get_config(c.sides[1]).width==1);assert(vim.api.nvim_win_get_config(c.sides[2]).border=='none')")
 lua("_G.click_source=vim.api.nvim_get_current_win();_G.click_buf=vim.api.nvim_create_buf(true,false);vim.api.nvim_buf_set_name(click_buf,'second-tab.lua');require('config.editor_card').refresh()")
 pos=lua("local c=require('config.editor_card').cards[click_source];local p=vim.api.nvim_win_get_position(c.header);for _,t in ipairs(c.tabs) do if t.buf==click_buf then return {p[1]+1,p[2]+t.first} end end")
 assert pos, 'second tab missing'
 for _ in range(2):
  request('nvim_input_mouse',['left','press','',0,pos[0],pos[1]])
  request('nvim_input_mouse',['left','drag','',0,pos[0],pos[1]+2])
  request('nvim_input_mouse',['left','release','',0,pos[0],pos[1]+2]);time.sleep(.08)
  lua("assert(vim.api.nvim_get_current_buf()==click_buf,'tab click did not switch file');assert(not vim.fn.mode():match('[vV]'),'tab click selected text')")
 lua("vim.api.nvim_set_hl(0,'IslandTabActive',{});vim.api.nvim_exec_autocmds('WinEnter',{});")
 time.sleep(.1)
 lua("assert(vim.api.nvim_get_hl(0,{name='IslandTabActive'}).bg==0x5fd7ff,'highlights require theme reload')")
 lua("_G.close_win=vim.api.nvim_get_current_win();vim.api.nvim_buf_set_lines(click_buf,0,-1,false,{'unsaved'});local original=vim.fn.confirm;vim.fn.confirm=function() return 3 end;require('config.buffers').close();vim.fn.confirm=original;assert(vim.api.nvim_buf_is_valid(click_buf) and vim.api.nvim_get_current_buf()==click_buf,'cancel discarded file')")
 request('nvim_input',[':bd!\r']);time.sleep(.2)
 lua("assert(vim.api.nvim_win_is_valid(close_win),'buffer close destroyed editor');assert(vim.api.nvim_get_current_win()==close_win);assert(vim.api.nvim_get_current_buf()~=click_buf);assert(not vim.api.nvim_buf_is_valid(click_buf));assert(vim.bo.buftype=='')")
 print('EDITOR_TABS_MOUSE_HIGHLIGHTS_AND_BUFFER_CLOSE_OK')
finally:
 p.kill()


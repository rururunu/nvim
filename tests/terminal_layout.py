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
 request('nvim_ui_attach',[160,45,{'rgb':True,'ext_linegrid':True}]);time.sleep(.6)
 lua("vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'});require('persistence').stop();vim.cmd('enew');vim.bo.swapfile=false;vim.api.nvim_buf_set_name(0,'terminal-layout-check.lua');vim.api.nvim_buf_set_lines(0,0,-1,false,vim.fn['repeat']({'source line'},100));_G.editor=vim.api.nvim_get_current_win();require('config.editor_card').refresh();_G.tt=require('config.terminal_tabs');tt.new()")
 time.sleep(.15)

 lua("_G.root=vim.w[tt.current.term.win].terminal_card_source;vim.api.nvim_win_set_height(root,16);require('config.editor_card').refresh();_G.height=vim.api.nvim_win_get_height(editor);tt.new()")
 time.sleep(.1)
 pos=lua("local p=vim.api.nvim_win_get_position(root);tt.winbar();local tab=tt.hitboxes[1];return {p[1]+1,p[2]+tab.first+1,tab.item.id}")
 request('nvim_input_mouse',['left','press','',0,pos[0],pos[1]])
 request('nvim_input_mouse',['left','release','',0,pos[0],pos[1]]);time.sleep(.1)
 lua("assert(tt.current.id=="+str(pos[2])+",'click must select terminal tab');assert(vim.wo[tt.current.term.win].winbar:find('TerminalTabsBar',1,true))")
 for i in range(24):
  lua("tt.cycle(1)")
  time.sleep(.03)
  lua("local c=require('config.editor_card').cards[editor];assert(vim.api.nvim_win_get_height(editor)==height,'editor height changed');assert(vim.w[tt.current.term.win].terminal_card_source==root,'container recreated');assert(vim.api.nvim_win_get_height(root)==16,'resized terminal height changed');assert(vim.api.nvim_win_get_height(c.header)==2 and vim.api.nvim_win_get_height(c.footer)==1,'decoration grew')")
 for i in range(4):
  lua("tt.toggle()")
  time.sleep(.03)
  lua("tt.toggle()")
  time.sleep(.03)
  lua("assert(vim.api.nvim_win_get_height(editor)==height,'hide/show changed editor height');assert(vim.api.nvim_win_get_height(vim.w[tt.current.term.win].terminal_card_source)==16)")
 print('TERMINAL_SWITCH_CONTAINER_HEIGHT_AND_HIDE_SHOW_OK')
finally:
 p.kill()

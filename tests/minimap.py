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
 request('nvim_ui_attach',[160,45,{'rgb':True,'ext_linegrid':True}]);time.sleep(.7)
 lua("vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'});require('persistence').stop();vim.cmd('enew');vim.bo.swapfile=false;vim.api.nvim_buf_set_name(0,'minimap-validation.lua');local lines={};for i=1,600 do lines[i]='local number_'..i..' = '..i end;vim.api.nvim_buf_set_lines(0,0,-1,false,lines);_G.source=vim.api.nvim_get_current_win();vim.bo.filetype='lua';require('config.editor_card').refresh()")
 time.sleep(1)
 print(lua("local map=require('neominimap.window.float.window_map').get_minimap_winid(source);assert(map and vim.api.nvim_win_is_valid(map),'minimap not created');_G.map=map;local cfg=vim.api.nvim_win_get_config(map);assert(cfg.win==source and cfg.width==16);assert(vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(map))>0);return {height=cfg.height,width=cfg.width,row=cfg.row,col=cfg.col}"))
 pos=lua("local c=vim.api.nvim_win_get_config(map);local p=vim.api.nvim_win_get_position(source);return {p[1]+math.floor(c.height/2),p[2]+c.col-c.width+4}")
 request('nvim_input_mouse',['left','press','',0,pos[0],pos[1]])
 request('nvim_input_mouse',['left','release','',0,pos[0],pos[1]]);time.sleep(.15)
 lua("assert(vim.api.nvim_win_get_cursor(source)[1]>1,'minimap click did not navigate')")
 lua("vim.cmd('Neominimap Disable')")
 time.sleep(.2)
 lua("assert(not vim.api.nvim_win_is_valid(map));vim.cmd('Neominimap Enable')")
 time.sleep(.3)
 lua("assert(require('neominimap.window.float.window_map').get_minimap_winid(source));local c=require('config.editor_card').cards[source];assert(not require('neominimap.window.float.window_map').get_minimap_winid(c.header));assert(not require('neominimap.window.float.window_map').get_minimap_winid(c.footer))")
 print('MINIMAP_RENDER_TOGGLE_AND_EDITOR_ONLY_OK')
finally:
 p.kill()

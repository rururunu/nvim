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
 lua("vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'});require('persistence').stop();vim.cmd('enew');vim.bo.swapfile=false;vim.api.nvim_buf_set_name(0,'close-tree-first.lua');_G.first=vim.api.nvim_get_current_buf();_G.second=vim.api.nvim_create_buf(true,false);vim.api.nvim_buf_set_name(second,'close-tree-second.lua');require('config.editor_card').refresh();_G.editor=vim.api.nvim_get_current_win();Snacks.explorer({cwd=vim.fn.getcwd()})")
 time.sleep(.3)
 lua("vim.api.nvim_set_current_win(editor)")
 request('nvim_input',[':bd\r']);time.sleep(.3)
 print(lua("return {editor_valid=vim.api.nvim_win_is_valid(editor),current=vim.api.nvim_get_current_win(),buf=vim.api.nvim_get_current_buf(),second=second,first_valid=vim.api.nvim_buf_is_valid(first),cmd=vim.fn.getcmdline()}"))
 lua("assert(vim.api.nvim_win_is_valid(editor),'editor closed');assert(vim.api.nvim_win_get_buf(editor)==second,'did not select second file');assert(vim.api.nvim_get_current_win()==editor,'focus moved to tree')")
 request('nvim_input',[':bd\r']);time.sleep(.3)
 print(lua("return {current=vim.bo.filetype,editor_valid=vim.api.nvim_win_is_valid(editor),windows=#vim.api.nvim_tabpage_list_wins(0)}"))
 print('BUFFER_CLOSE_WITH_EXPLORER_OK')
finally:
 p.kill()

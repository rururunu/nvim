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
 request('nvim_ui_attach',[180,55,{'rgb':True,'ext_linegrid':True}]);time.sleep(.6)
 lua("vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'});require('persistence').stop();_G.r=vim.fn.tempname()..'-workspace-ui';vim.fn.mkdir(r,'p');for _,f in ipairs({'a.lua','b.lua','hidden.lua'}) do vim.fn.writefile(vim.fn['repeat']({'local value = 42'},100),r..'/'..f) end;local cards=require('config.editor_card');cards.clear();cards.suspended=true;vim.cmd('edit '..vim.fn.fnameescape(r..'/a.lua'));_G.a=vim.api.nvim_get_current_buf();vim.cmd('rightbelow vsplit '..vim.fn.fnameescape(r..'/b.lua'));_G.b=vim.api.nvim_get_current_buf();_G.focus=vim.api.nvim_get_current_win();vim.api.nvim_win_set_width(focus,110);vim.api.nvim_win_set_cursor(focus,{40,3});_G.hidden=vim.fn.bufadd(r..'/hidden.lua');vim.fn.bufload(hidden);vim.bo[hidden].buflisted=true;vim.t.workspace_path=r;vim.cmd('tcd '..vim.fn.fnameescape(r));cards.suspended=false;cards.refresh();Snacks.explorer({cwd=r});vim.api.nvim_set_current_win(focus);assert(require('config.workspace').save());_G.snapshot=vim.fn.stdpath('state')..'/workspaces/'..vim.fn.sha256(r:lower())..'.json'")
 time.sleep(.2)
 lua("_G.tt=require('config.terminal_tabs');tt.new();tt.new();vim.api.nvim_set_current_win(focus);vim.api.nvim_win_set_cursor(focus,{40,3});assert(require('config.workspace').save());local st=vim.json.decode(table.concat(vim.fn.readfile(snapshot),'\\n'));assert(st.sidebar,'sidebar state missing');_G.expected=st.layout;vim.bo[hidden].buflisted=false;assert(require('config.workspace').restore());assert(vim.bo[hidden].buflisted,'hidden buffer not restored');assert(vim.api.nvim_get_current_buf()==b,'active file not restored');assert(vim.api.nvim_win_get_cursor(0)[1]==40,'cursor='..vim.inspect(vim.api.nvim_win_get_cursor(0))..' state='..vim.inspect(expected));assert(#tt.items==4,'terminal tabs not recreated');assert(vim.api.nvim_win_get_tabpage(tt.current.term.win)==vim.api.nvim_get_current_tabpage(),'terminal attached to previous workspace')")
 time.sleep(.3)
 print(lua("local w={};for _,x in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.api.nvim_win_get_config(x).relative=='' and vim.bo[vim.api.nvim_win_get_buf(x)].buftype=='' then w[#w+1]=vim.api.nvim_win_get_width(x) end end;assert(#w==2,'file split count');return w"))
 lua("vim.fn.delete(snapshot)")
 print('WORKSPACE_HIDDEN_BUFFERS_LAYOUT_FOCUS_CURSOR_OK')
finally:
 p.kill()

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
    request('nvim_ui_attach',[160,45,{'rgb':True,'ext_linegrid':True}])
    time.sleep(1)
    lua("vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'}); require('persistence').stop(); require('config.recent_projects').record=function() end; vim.o.confirm=false")
    lua("local r=vim.fn.tempname()..'-ui';vim.fn.mkdir(r..'/a','p');vim.fn.mkdir(r..'/b','p');vim.fn.writefile({'one'},r..'/a/file.txt');vim.fn.writefile({'two'},r..'/b/file.txt');_G.uiroot=r;vim.cmd('edit '..vim.fn.fnameescape(r..'/a/file.txt'));vim.t.workspace_path=r..'/a';vim.cmd('tcd '..vim.fn.fnameescape(r..'/a'));_G.ub=vim.api.nvim_get_current_buf();vim.api.nvim_buf_set_lines(ub,0,1,false,{'unsaved'})")
    lua("require('config.recent_projects').switch(uiroot..'/b')")
    time.sleep(.6)
    lua("assert(vim.bo[ub].modified);for _,picker in ipairs(Snacks.picker.get()) do picker:close() end;assert(vim.fn.getcwd():find('/b',1,true) or vim.fn.getcwd():find('\\\\b',1,true))")
    lua("require('config.recent_projects').switch(uiroot..'/a');assert(vim.api.nvim_get_current_buf()==ub);assert(vim.api.nvim_win_get_config(0).relative=='');assert(not vim.o.autowriteall)")
    lua("vim.cmd('vsplit');vim.cmd('new');assert(vim.api.nvim_win_get_config(0).relative=='');vim.cmd('close');vim.cmd('close')")
    lua("_G.ut=Snacks.terminal({'cmd.exe','/Q'},{interactive=true});assert(vim.w[ut.win].terminal_card_source)")
    time.sleep(.4)
    lua("require('config.window_navigation').move('k');assert(vim.bo.filetype~='snacks_terminal');_G.mouse_editor=vim.api.nvim_get_current_win()")
    pos=lua("local p=vim.api.nvim_win_get_position(vim.w[ut.win].terminal_card_source);return p")
    request('nvim_input_mouse',['left','press','',0,pos[0]+2,pos[1]+3])
    request('nvim_input_mouse',['left','release','',0,pos[0]+2,pos[1]+3]);time.sleep(.1)
    lua("assert(vim.api.nvim_get_current_win()==ut.win, 'mouse must focus terminal')")
    pos=lua("return vim.api.nvim_win_get_position(mouse_editor)")
    request('nvim_input_mouse',['left','press','',0,pos[0]+1,pos[1]+8])
    request('nvim_input_mouse',['left','release','',0,pos[0]+1,pos[1]+8]);time.sleep(.1)
    lua("assert(vim.api.nvim_get_current_win()==mouse_editor, 'mouse must focus editor');require('config.window_navigation').move('j');assert(vim.api.nvim_get_current_win()==ut.win);require('config.window_navigation').move('k');assert(vim.bo.buftype=='');ut:hide()")
    lua("vim.cmd('Workbench')")
    time.sleep(.2)
    lua("assert(#Snacks.picker.get()>0);for _,picker in ipairs(Snacks.picker.get()) do picker:close() end")
    lua("for _,w in ipairs(vim.api.nvim_list_wins()) do assert(vim.bo[vim.api.nvim_win_get_buf(w)].filetype~='editor_card_container') end")
    assert any(m[1]=='redraw' for m in events), 'UI redraw events'
    print('EMBEDDED_UI_PROJECT_FOCUS_SPLIT_TERMINAL_MENU_OK',len(events),'events')
finally:
    if p.poll() is None:
        p.stdin.write(msgpack.packb([2,'nvim_command',['qa!']],use_bin_type=True));p.stdin.flush()
        try:p.wait(timeout=10)
        except subprocess.TimeoutExpired:p.kill()



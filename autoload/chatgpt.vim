scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    if has('nvim')
      let s:ch = jobstart(['chatgpt', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1, 'on_stdout': function('s:nvim_chatgpt_cb_out'), 'on_stderr': function('s:nvim_chatgpt_cb_err')})
    else
      let s:job = job_start(['chatgpt', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1})
      let s:ch = job_getchannel(s:job)
    endif
  endif
  return s:ch
endfunction

function! s:chatgpt_cb_out(msgs) abort
  let l:winid = bufwinid('__CHATGPT__')
  if l:winid ==# -1
    silent noautocmd split __CHATGPT__
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal wrap nonumber signcolumn=no filetype=markdown
    wincmd p
    let l:winid = bufwinid('__CHATGPT__')
  endif
  call win_execute(l:winid, 'setlocal modifiable', 1)
  for l:json_string in a:msgs
    if l:json_string ==# ''
      continue
    endif
    let l:msg = json_decode(l:json_string)
    call win_execute(l:winid, 'silent normal! GA' .. l:msg['text'], 1)
    if l:msg['error'] != ''
      call win_execute(l:winid, 'silent normal! Go' .. l:msg['error'], 1)
    elseif l:msg['eof']
      call win_execute(l:winid, 'silent normal! Go', 1)
    endif
  endfor
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! s:chatgpt_cb_err(msg) abort
  echohl ErrorMsg | echom '[chatgpt ch err] ' .. string(a:msg) | echohl None
endfunction

function! s:vim_chatgpt_cb_out(ch, msg) abort
    call s:chatgpt_cb_out([a:msg])
endfunction

function! s:nvim_chatgpt_cb_out(job_id, data, event) abort
    call s:chatgpt_cb_out(a:data)
endfunction

function! s:vim_chatgpt_cb_err(ch, msg) abort
    call s:chatgpt_cb_err(a:msg)
endfunction

function! s:nvim_chatgpt_cb_err(job_id, data, event) abort
    call s:chatgpt_cb_err(a:data)
endfunction

function! chatgpt#send(text) abort
  let l:ch = s:get_channel()
  if has('nvim')
    call chansend(l:ch, json_encode({'text': a:text}))
  else
    call ch_setoptions(l:ch, {'out_cb': function('s:vim_chatgpt_cb_out'), 'err_cb': function('s:vim_chatgpt_cb_err')})
    call ch_sendraw(l:ch, json_encode({'text': a:text}))
  endif
endfunction

function! chatgpt#code_review_please() abort
  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please code review'
  let l:lines = [
  \  l:question,
  \  '',
  \] + getline(1, '$')
  call chatgpt#send(join(l:lines, "\n"))
endfunction

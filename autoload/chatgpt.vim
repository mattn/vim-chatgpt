scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    let s:job = job_start(['chatgpt', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1})
    let s:ch = job_getchannel(s:job)
  endif
  return s:ch
endfunction

function! s:chatgpt_callback(ch, msg) abort
  let l:msg = json_decode(a:msg)
  let l:winid = bufwinid('__CHATGPT__')
  if l:winid ==# -1
    silent noautocmd split __CHATGPT__
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal wrap nonumber signcolumn=no filetype=markdown
    wincmd p
    let l:winid = bufwinid('__CHATGPT__')
  endif
  call win_execute(l:winid, 'setlocal modifiable', 1)
  call win_execute(l:winid, 'silent normal! GA' .. l:msg['text'], 1)
  if l:msg['error'] != ''
    call win_execute(l:winid, 'silent normal! Go' .. l:msg['error'], 1)
  elseif l:msg['eof']
    call win_execute(l:winid, 'silent normal! Go', 1)
  endif
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! chatgpt#send(text) abort
  let l:ch = s:get_channel()
  call ch_setoptions(l:ch, {'out_cb': function('s:chatgpt_callback')})
  call ch_sendraw(l:ch, json_encode({'text': a:text}))
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

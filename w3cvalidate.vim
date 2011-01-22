if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif


function! s:W3cValidate(...)
python << EOF
import vim, urllib2, urllib, simplejson

OUTPUT = 'json'
VERBOSE = 0
TIMEOUT = 20
URL = 'http://validator.w3.org/check'


fragment = ''.join(vim.current.buffer)

post_dat = {"output": OUTPUT, "verbose": VERBOSE}

if int(vim.eval("a:0")) > 0:
    url_check = vim.eval("a:1")
    post_dat.update({"uri": url_check})
    URL += "?" + urllib.urlencode(post_dat)
    post_dat = None
else:
    post_dat.update({"fragment": fragment})
    post_dat = urllib.urlencode(post_dat)

try:
    response = urllib2.urlopen(URL, post_dat, TIMEOUT).read()
    messages = simplejson.loads(response).get("messages", [])

    vim.command("call s:W3ScratchBufferOpen()")
    del vim.current.buffer[:]
    
    vim.current.buffer.append("")

    valid = True 
    for message in messages:
        if message["type"] == "error":
            valid = False
        vim.current.buffer.append("Type: %s | Line: %s | Column: %s" %
                    (str.capitalize(message["type"]), message["lastLine"],
                    message["lastColumn"],))
        vim.current.buffer.append(str.capitalize(message["message"]))
        vim.current.buffer.append("")

    if valid:
        vim.current.buffer[0] = "The Document is VALID"
    else:
        vim.current.buffer[0] = "The Document is INVALID"

    vim.command("match ErrorMsg 'Type\: Error.*$'")

except:
    print "Can not connect to the web service. Try again."

EOF
endfunction


let W3ScratchBufferName = "W3ScratchBuffer__"

function! s:W3ScratchBufferOpen()
    
    let scr_bufnum = bufnr(g:W3ScratchBufferName)
    if scr_bufnum == -1
        exe "new " . g:W3ScratchBufferName
    else
        let scr_winnum = bufwinnr(scr_bufnum)
        if scr_winnum != -1
            if winnr() != scr_winnum
                exe scr_winnum . "wincmd w"
            endif
        else
            exe "split +buffer" . scr_bufnum
        endif
    endif
endfunction


function! s:W3ScratchBuffer()
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal buflisted
endfunction


autocmd BufNewFile W3ScratchBuffer__ call s:W3ScratchBuffer()

command! -nargs=? W3cValidate call s:W3cValidate(<args>)

"=============================================================================
" File: w3cvalidate.vim
" Author: Dejan Noveski <dr.mote@gmail.com>
" Last Change: 23-Jan-2010.
" Version: 0.3
" WebPage: http://github.com/dekomote/w3cvalidate.vim
" Description: vim plugins for W3C validation of buffer/url
" Usage:
"   :W3cValidate - validates the buffer
"   :W3cValidate [url] - validates an URL
"   :W3cValidateDT [doctype] - validates the buffer using [doctype] override
"
" Tips:
"   Set g:w3_validator_url if you run a local instance of the w3 validator
"   Set g:w3_apicall_timeout to change the timeout of the api calls
"
"
"   You can set language attribute in html using 'zen_settings.lang'.
"
" GetLatestVimScripts: 3416 1 :AutoInstall: w3cvalidate.vim
" script type: plugin


if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

if !exists("g:w3_validator_url")
    let g:w3_validator_url = "http://validator.w3.org/check"
endif

if !exists("g:w3_apicall_timeout")
    let g:w3_apicall_timeout = 20
endif

if !exists("g:w3_doctype_override")
    let g:w3_doctype_override="Inline"
endif

function! s:W3cValidate(...)
python << EOF
import vim, urllib2, urllib, re
try:
    import simplejson as json
except ImportError:
    import json

OUTPUT = 'json'
VERBOSE = 0
TIMEOUT = int(vim.eval("g:w3_apicall_timeout"))
URL = vim.eval("g:w3_validator_url")
DOCTYPE = vim.eval("g:w3_doctype_override")

fragment = ''.join(vim.current.buffer)

post_dat = {"output": OUTPUT, "verbose": VERBOSE, "doctype": DOCTYPE}

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
    json_response = json.loads(response)
    messages = json_response.get("messages", [])
    
    vim.command("call s:W3ScratchBufferOpen()")
    del vim.current.buffer[:]
    
    vim.current.buffer.append("")

    valid = True 
    for message in messages:
        explanation = str(message.get("explanation", "")).replace("\n"," ")
        explanation = explanation.replace("&#x2709;", "")
        explanation = re.sub(r"\s+", " ", explanation)
        explanation = re.sub(r"<(.[^<])*>","", explanation)
        explanation = re.sub(r"^\s+", "", explanation)
        explanation = explanation.replace("&lt;", "<")
        explanation = explanation.replace("&gt;", ">")

        if message["type"] == "error":
            valid = False
        vim.current.buffer.append("Type: %s | Line: %s | Column: %s" %
                    (str.capitalize(message["type"]), message["lastLine"],
                    message["lastColumn"],))
        vim.current.buffer.append(str.capitalize(message["message"]))
        vim.current.buffer.append(explanation)
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

function! s:W3cValidateDT(doctype)
    let g:w3_doctype_override = a:doctype
    call s:W3cValidate()
    let g:w3_doctype_override = "Inline"
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
command! -nargs=1 W3cValidateDT call s:W3cValidateDT(<args>)

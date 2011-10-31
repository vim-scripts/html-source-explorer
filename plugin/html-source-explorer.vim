let g:se_default_extension = 'html'
let g:se_http_handler = 'wget' "or Nread

function! s:SetFileType(Url)
    let regexp = 'http://.*/.*\.\([a-z0-9]\{1,4}\)\(?.*\)\?$'
    let l = matchlist(a:Url,regexp)
    if len(l)>2 && strlen(l[1])>0
        let extension = l[1]
    else
        let extension = g:se_default_extension
    endif
        exec 'set filetype='.extension
endfunction

function! s:wget(Url)
    let b:Url = a:Url
    exec '%!wget -q -O - '.a:Url
    call s:SetFileType(a:Url)
endfunction

function! g:FollowUrl(Url)
    let url = a:Url
    let remote = 0
    if(match(a:Url,'http://.*')<0)
        if(exists('b:Url'))
            if(a:Url[0] == '/')
                let prefix = matchstr(b:Url,'http://.*/\?')
                if(prefix[strlen(prefix)-1] == '/')
                    let url = prefix.strpart(a:Url,1)
                else
                    let url = prefix.a:Url
                endif
                let remote = 1
            else
                let i = match(b:Url,'[^/]\{-}$')
                if(i>0)
                    let url = strpart(b:Url,0,i).a:Url
                    let remote = 1
                else
                    return
                endif
            endif
        else       
            if(a:Url[0] != '/')
                 let url = expand('%:p:h').'/'.a:Url
            endif
        endif
    else
        let url = a:Url
        let remote = 1
    endif
    if(remote)
        enew
        if(g:se_http_handler == 'wget')
            call s:wget(url)
        else
           exec 'Nread '.url
           call s:SetFileType(url)
        endif
    else
        exec 'e '.url
    endif
endfunction

function! g:FollowUrlUnderCursor(limiter)
    let pos = getpos('.')[2]
    let line = getline('.')
    let regex =  a:limiter[0].'.\{-}'.a:limiter[1]
    let mpos = match(line,regex)
    while(mpos>-1)
        let match_str = matchstr(line,regex,mpos)
        if(pos >= mpos && pos <= mpos + strlen(match_str))
            let url = strpart(match_str,1,strlen(match_str)-2)
            if(match(url,'^http://\|^/\|^\./\|^\.\./')==0)
                call g:FollowUrl(url)
                return a:limiter
            endif
            return 0
        endif
        let mpos = match(line, regex, mpos+1)
    endwhile
    return 0
endfunction

command -nargs=1 -bar Wget call <SID>wget(<q-args>)
command Follow if g:FollowUrlUnderCursor('""') || g:FollowUrlUnderCursor("''") ||  g:FollowUrlUnderCursor('()') | echo '' | endif

map <leader>fl :Follow<CR>


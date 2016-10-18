"
" viewer.vim  in ftplugin/markdown/
"
"


if &cp || exists('g:mmdv_loaded')
    finish
endif
let g:mmdv_loaded = 1
let s:save_cpo = &cpo
set cpo&vim

let s:scriptPath = expand('<sfile>:p:h')

if !exists('g:mmdv_theme')
    let g:mmdv_theme = 'default'
endif

function! s:OpenFile(filePath)

    let path = shellescape(a:filePath)
    let cmdStr = ''

    if has('mac')
        let cmdStr = 'open -a Safari ' . path
        let findStr = system('ls /Applications/ | grep -i google\ chrome')
        if strlen(findStr) > 5
            let cmdStr = 'open -a Google\ Chrome ' . path
        endif
    elseif has('win32') || has('win64') || has('win95') || has('win16')
        let cmdStr = 'cmd /c start "" ' . path
    else
        echomsg 'Can NOT open ' . a:filePath
        return
    endif

    call system(cmdStr)
    echo cmdStr

endfunction

" reuturn {String}
function s:ReadFile(file, spliter)
    let filePath = s:scriptPath . a:file
    if filereadable(filePath)
        return join(readfile(filePath, 'b'), a:spliter)
    endif
    return ''
endfunction

"@param {String} theme
"@param {String} content
"@return {Array<String>}
function s:MakeUpHtml(theme, content)
    let cssFileMiddle = ''
    if a:theme ==? 'dark'
        let cssFileMiddle = '.dark'
    elseif a:theme ==? 'forest'
        let cssFileMiddle = '.forest'
    endif

    let style_path = s:scriptPath . '/bower_components/mermaid/dist/mermaid' . cssFileMiddle . '.css'
    let mermaid_path = s:scriptPath . '/bower_components/mermaid/dist/mermaid.min.js'

    let html = s:ReadFile('/bone.html', '')
    let html = substitute(html, '{{style-path}}', style_path, '')
    let html = substitute(html, '{{mermaid-path}}', mermaid_path, '')
    let html = substitute(html, '{{content}}', a:content, '')
    let lines = split(html, '\n')

    return lines
endfunction


"@return {Array<String>}
function! s:Convert2Html()
    let lines = getline(1, '$')
    let content = join(lines, '\n')
    let htmlLines = s:MakeUpHtml(g:mmdv_theme, content)
    return htmlLines
endfunction

"
"write html to file
"@param {Boolean} saveHtml  save html to the folder that include markdown file
function! s:WriteHtml()
    let lines = s:Convert2Html()
    if exists('b:temp_html_file')
        call writefile(lines, b:temp_html_file, '')
    endif
endfunction

function! s:RemoveTempHtml()
    if exists('b:temp_html_file')
        call delete(b:temp_html_file)
    endif
endfunction


function! s:ViewMermaid()
    if !exists('b:temp_html_file')
        let file_name = expand('%:t')
        let file_path = expand('%:p:h')
        let b:temp_html_file = file_path . '/.' . file_name . '.temp.html'
    endif
    call s:WriteHtml()
    call s:OpenFile(b:temp_html_file)
endfunction


function! s:AutoRenderWhenSave()
    call s:WriteHtml()
endfunction


command -nargs=0 MmdView call s:ViewMermaid()

augroup mermaidviewer
    autocmd!
    autocmd QuitPre,BufDelete,BufUnload,BufHidden,BufWinLeave     *.mmd   call s:RemoveTempHtml()
    autocmd BufWritePre *.mmd   call s:AutoRenderWhenSave()
augroup END


let &cpo = s:save_cpo

protocol = window.location.href.split('://')[0]
if protocol is 'file' then protocol = 'http'

base_url = "#{protocol}://filestrash.com/api/v1"

token = ''

class ApiError extends Error
    constructor: (message) ->
        super()
        @name = 'ApiError'
        @message = message

class NetworkError extends Error
    constructor: (message) ->
        super()
        @name = 'NetworkError'
        @message = message


_do_file_upload = (params, upload_url, cb) ->
    form_data = new FormData()
    form_data.append("file", params.file)
    form_data.append("token", params.token || token)
    upload_progress = (event) =>
        if event.lengthComputable
            if params.progress_cb && typeof params.progress_cb == 'function'
                params.progress_cb(Math.ceil(event.loaded / event.total * 100))

    xhr = new XMLHttpRequest()
    xhr.open("POST", upload_url, true)
    xhr.upload.onprogress = upload_progress
    xhr.onreadystatechange = ->
        if xhr.readyState is 4 and xhr.status is 200
            data = JSON.parse(xhr.responseText)
            response = data.response
            if data.status is 200
                if cb && typeof cb == 'function' then cb(null, data.response.file)
            else
                if cb && typeof cb == 'function'
                    cb(new ApiError("#{data.details}(#{data.status})"))
        else if xhr.readyState is 4 and xhr.status isnt 200
            if cb && typeof cb == 'function' 
                cb(new NetworkError("#{status}(#{xhr.status})"))
    
    xhr.send(form_data)

_fldr_ops = ['info', 'content', 'create', 'rename']
_item_method_helper = (itype, method, params, response_field, cb) ->
    params.token = params.token || token

    params_str = ''
    for k, v of params
        if typeof v isnt 'function' then params_str += "#{k}=#{encodeURIComponent(v)}&"

    xhr = new XMLHttpRequest()
    xhr.open("GET", "#{base_url}/#{itype}/#{method}?#{params_str}", true)
    xhr.onreadystatechange = ->
        if xhr.readyState is 4 and xhr.status is 200
            data = JSON.parse(xhr.responseText)

            if data.status is 200 and data.response
                # return the default result or a special field?
                result = if response_field then data.response[response_field] else data.response

                # two-level method or not?
                twolevel = false

                if itype is 'user' and method is 'login'
                    token = data.response.token # set global token on login
                else if itype is 'file' and method is 'upload' # file upload method
                    if data.response.upload_url 
                        twolevel = true # it's a two-level operation
                        _do_file_upload(params, data.response.upload_url, cb) 
                
                # by default: call passed callback with a response result
                if cb && typeof cb == 'function' && (not twolevel)
                    cb(null, result)
            else
                # once the response status in not 200, we should pass an ApiError to callback
                if cb && typeof cb == 'function'
                    cb(new ApiError("#{data?.details}(#{data?.status})"))
        else if xhr.readyState is 4 and xhr.status isnt 200
            if cb && typeof cb == 'function' 
                cb(new NetworkError("#{status}(#{xhr.status})"))
    
    xhr.send()

userLogin = (login, password, cb) ->
    _item_method_helper('user', 'login', {login: login, password: password}, 'user', cb)

userInfo = (cb) ->
    _item_method_helper('user', 'info', {}, 'user', cb)


fileUpload = (name, hash, size, file, options, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 5 then params = options

    params.name = name
    params.hash = hash
    params.size = size
    params.file = file

    # params = {name: name, hash: hash, size: size, file: file, progress_cb: progress_cb}
    _item_method_helper('file', 'upload', params, 'file', cb)

fileRename = (file_id, name, cb) ->
    params = {file_id: file_id, name: name}
    _item_method_helper('file', 'rename', params, 'file', cb)

fileDelete = (file_id, cb) ->
    params = {file_id: file_id}
    _item_method_helper('file', 'delete', params, 'result', cb)

fileCopy = (file_id, folder_id_dest, cb) ->
    params = {file_id: file_id, folder_id_dest: folder_id_dest}
    _item_method_helper('file', 'copy', params, 'result', cb)

fileMove = (file_id, folder_id_dest, cb) ->
    params = {file_id: file_id, folder_id_dest: folder_id_dest}
    _item_method_helper('file', 'move', params, 'result', cb)


folderInfo = (options, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 1 then params = options # user wants to pass custom fields
    
    _item_method_helper('folder', 'info', params, 'folder', cb)

folderContent = (options, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 1 then params = options # user wants to pass a custom fields
    
    _item_method_helper('folder', 'content', params, 'folder', cb)

folderCreate = (name, options, cb) ->
    params = {name: name}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 2 
        for k,v of options
            params[k] = v

    _item_method_helper('folder', 'create', params, 'folder', cb)

folderRename = (folder_id, name, cb) ->
    params = {name: name, folder_id: folder_id}
    _item_method_helper('folder', 'rename', params, 'folder', cb)

folderDelete = (folder_id, cb) ->
    params = {folder_id: folder_id}
    _item_method_helper('folder', 'delete', params, 'result', cb)

folderCopy = (folder_id, folder_id_dest, cb) ->
    params = {folder_id: folder_id, folder_id_dest: folder_id_dest}
    _item_method_helper('folder', 'copy', params, 'result', cb)

folderMove = (folder_id, folder_id_dest, cb) ->
    params = {folder_id: folder_id, folder_id_dest: folder_id_dest}
    _item_method_helper('folder', 'move', params, 'result', cb)


trashcanContent = (cb) ->
    _item_method_helper('trashcan', 'content', {}, null, cb)

trashcanEmpty = (options, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 1 then params = options # user wants to pass a custom fields

    _item_method_helper('trashcan', 'empty', params, 'result', cb)

trashcanRestore = (options, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 1 then params = options # user wants to pass a custom fields

    _item_method_helper('trashcan', 'restore', params, 'result', cb)


window.FTClient = FTClient = {
    # internal stuff, can monkeypatch thought
    _setToken: (newToken) ->
        token = newToken
    _setBaseUrl: (newBaseUrl) ->
        base_url = newBaseUrl
    # error types
    ApiError: ApiError
    NetworkError: NetworkError
    # api methods
    userLogin: userLogin
    userInfo: userInfo

    fileUpload: fileUpload
    fileRename: fileRename
    fileDelete: fileDelete
    fileMove: fileMove
    fileCopy: fileCopy

    folderInfo: folderInfo
    folderContent: folderContent
    folderCreate: folderCreate
    folderRename: folderRename
    folderDelete: folderDelete
    folderCopy: folderCopy
    folderMove: folderMove

    trashcanContent: trashcanContent
    trashcanEmpty: trashcanEmpty
    trashcanRestore: trashcanRestore
}

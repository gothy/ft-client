base_url = 'http://filestrash.com/api/v1'

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
                    cb(new ApiError("#{data.status}: #{data.details}"))
        else if xhr.readyState is 4 and xhr.status isnt 200
            if cb && typeof cb == 'function' 
                cb(new NetworkError("#{xhr.status}: #{status}"))
    
    xhr.send(form_data)

_fldr_ops = ['info', 'content', 'create', 'rename']
_item_method_helper = (itype, method, params, cb) ->
    params.token = params.token || token

    params_str = ''
    for k, v of params
        if typeof v isnt 'function' then params_str += "#{k}=#{encodeURIComponent(v)}&"

    xhr = new XMLHttpRequest()
    xhr.open("GET", "#{base_url}/#{itype}/#{method}?#{params_str}", true)
    xhr.onreadystatechange = ->
        if xhr.readyState is 4 and xhr.status is 200
            data = JSON.parse(xhr.responseText)
            response = data.response

            if data.status is 200
                twolevel = false
                if itype is 'file' and method is 'upload' 
                    if data.response.upload_url # file upload
                        _do_file_upload(params, data.response.upload_url, cb) 
                        twolevel = true
                    else
                        result = data?.response?.file
                else if (itype is 'file' and method is 'rename') or
                        (itype is 'folder' and method in _fldr_ops) # file and folder methods
                    result = data?.response?[itype]
                else if itype is 'user' # user methods
                    if method is 'login'
                        token = data.response.token
                        result = data.response
                    else if method is 'info'
                        result = data.response.user
                else if (itype is 'trashcan' and method is 'content') # trashcan methods
                    result = data?.response?.files
                else 
                    result = data?.response?.result

                if cb && typeof cb == 'function' && (not twolevel)
                    cb(null, result)
            else
                if cb && typeof cb == 'function'
                    cb(new ApiError("#{data?.status}: #{data?.details}"))
        else if xhr.readyState is 4 and xhr.status isnt 200
            if cb && typeof cb == 'function' 
                cb(new NetworkError("#{xhr.status}: #{status}"))
    
    xhr.send()

userLogin = (login, password, cb) ->
    _item_method_helper('user', 'login', {login: login, password: password}, cb)

userInfo = (cb) ->
    _item_method_helper('user', 'info', {}, cb)


fileUpload = (name, hash, size, file, progress_cb, cb) ->
    _item_method_helper('file', 'upload', {
        name: name
        hash: hash
        size: size
        file: file
        progress_cb: progress_cb
    }, cb)

fileRename = (file_id, name, cb) ->
    params = {file_id: file_id, name: name}
    _item_method_helper('file', 'rename', params, cb)

fileDelete = (file_id, cb) ->
    params = {file_id: file_id}
    _item_method_helper('file', 'delete', params, cb)

fileCopy = (file_id, folder_id_dest, cb) ->
    params = {file_id: file_id, folder_id_dest: folder_id_dest}
    _item_method_helper('file', 'copy', params, cb)

fileMove = (file_id, folder_id_dest, cb) ->
    params = {file_id: file_id, folder_id_dest: folder_id_dest}
    _item_method_helper('file', 'move', params, cb)


folderInfo = (folder_id, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 1 # user wants to pass a custom folder_id
        params.folder_id = args.shift()
    _item_method_helper('folder', 'info', params, cb)

folderContent = (folder_id, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    if args.length is 1 # user wants to pass a custom folder_id
        params.folder_id = args.shift()
    _item_method_helper('folder', 'content', params, cb)

folderCreate = (name, folder_id, cb) ->
    params = {}
    args = Array.prototype.slice.call(arguments)
    cb = args.pop()
    params.name = args.shift()
    if args.length is 1 # user wants to pass a custom folder_id
        params.folder_id = args.shift()

    _item_method_helper('folder', 'create', params, cb)

folderRename = (folder_id, name, cb) ->
    params = {name: name, folder_id: folder_id}
    _item_method_helper('folder', 'rename', params, cb)

folderDelete = (folder_id, cb) ->
    params = {folder_id: folder_id}
    _item_method_helper('folder', 'delete', params, cb)

folderCopy = (folder_id, folder_id_dest, cb) ->
    params = {folder_id: folder_id, folder_id_dest: folder_id_dest}
    _item_method_helper('folder', 'copy', params, cb)

folderMove = (folder_id, folder_id_dest, cb) ->
    params = {folder_id: folder_id, folder_id_dest: folder_id_dest}
    _item_method_helper('folder', 'move', params, cb)


trashcanContent = (cb) ->
    _item_method_helper('trashcan', 'content', {}, cb)

trashcanEmpty = (cb) ->
    _item_method_helper('trashcan', 'empty', {}, cb)

trashcanRestore = (cb) ->
    _item_method_helper('trashcan', 'restore', {}, cb)


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

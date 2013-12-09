base_url = 'http://filestrash.com/api/v1'

token = null

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


userLogin = (login, password, cb) ->
    $.ajax
        url: "#{base_url}/user/login"
        data:
            login: login
            password: password
    .done (data) =>
        data = JSON.parse(data)
        if data.status is 200
            token = data.response.token
            if cb && typeof cb == 'function' then cb(null, data.response)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data.status}: #{data.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

userInfo = (params, cb) ->
    if arguments.length is 2 # user wants to pass a custom param
        params.token = params.token || token
    else if arguments.length is 1 and typeof params is 'function'
        cb = params

    $.ajax
        url: "#{base_url}/user/info"
        data: params
    .done (data) =>
        data = JSON.parse(data)
        if data.status is 200
            if cb && typeof cb == 'function' then cb(null, data.response.user)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data.status}: #{data.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

fileUpload = (params, file, progress_cb, cb) ->
    params.token = params.token || token
    $.ajax
        url: "#{base_url}/file/upload"
        data: params
    .done (data) =>
        data = JSON.parse(data)
        response = data.response
        if data.status is 200
            if response.upload_url
                _do_file_upload(params, file, response.upload_url, progress_cb, cb)
            else
                if cb && typeof cb == 'function' then cb(null, data.response.file)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data.status}: #{data.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

_do_file_upload = (params, file, upload_url, progress_cb, cb) ->
    form_data = new FormData()
    form_data.append("file", file)
    form_data.append("token", params.token || token)
    upload_progress = (event) =>
        if event.lengthComputable
            if progress_cb && typeof progress_cb == 'function'
                progress_cb(Math.ceil(event.loaded / event.total * 100))

    $.ajax
        url: upload_url
        type: 'POST'
        data: form_data
        cache: false
        contentType: false
        processData: false
        xhr: ->
            myXhr = $.ajaxSettings.xhr()
            if myXhr.upload
                myXhr.upload.addEventListener('progress', upload_progress, false)
            return myXhr
    .done (data) =>
        data = JSON.parse(data)
        if data.status is 200
            if cb && typeof cb == 'function' then cb(null, data.response.file)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data.status}: #{data.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))


_file_method_helper = (method, params, cb) ->
    params.token = params.token || token
    $.ajax
        url: "#{base_url}/file/#{method}"
        data: params
    .done (data) =>
        data = JSON.parse(data)
        response = data.response
        if data.status is 200
            result = if method is 'rename' then data?.response?.file else data?.response?.result

            if cb && typeof cb == 'function' then cb(null, result)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data?.status}: #{data?.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))


fileRename = (params, cb) ->
    _file_method_helper('rename', params, cb)

fileDelete = (params, cb) ->
    _file_method_helper('delete', params, cb)

fileCopy = (params, cb) ->
    _file_method_helper('copy', params, cb)

fileMove = (params, cb) ->
    _file_method_helper('move', params, cb)


_fldr_ops = ['info', 'content', 'create', 'rename']
_folder_method_helper = (method, params, cb) ->
    params.token = params.token || token
    $.ajax
        url: "#{base_url}/folder/#{method}"
        data: params
    .done (data) =>
        data = JSON.parse(data)
        response = data.response
        if data.status is 200
            if method in _fldr_ops 
                result = data?.response?.folder 
            else 
                result = data?.response?.result

            if cb && typeof cb == 'function' then cb(null, result)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data?.status}: #{data?.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

folderInfo = (params, cb) ->
    _folder_method_helper('info', params, cb)

folderContent = (params, cb) ->
    _folder_method_helper('content', params, cb)

folderCreate = (params, cb) ->
    _folder_method_helper('create', params, cb)

folderRename = (params, cb) ->
    _folder_method_helper('rename', params, cb)

folderDelete = (params, cb) ->
    _folder_method_helper('delete', params, cb)

folderCopy = (params, cb) ->
    _folder_method_helper('copy', params, cb)

folderMove = (params, cb) ->
    _folder_method_helper('move', params, cb)


_trashcan_method_helper = (method, params, cb) ->
    params.token = params.token || token
    $.ajax
        url: "#{base_url}/trashcan/#{method}"
        data: params
    .done (data) =>
        data = JSON.parse(data)
        response = data.response
        if data.status is 200
            if method is 'content'
                result = data?.response?.files
            else
                result = data?.response?.result

            if cb && typeof cb == 'function' then cb(null, result)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data?.status}: #{data?.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

trashcanContent = (params, cb) ->
    _trashcan_method_helper('content', params, cb)

trashcanEmpty = (params, cb) ->
    _trashcan_method_helper('empty', params, cb)

trashcanRestore = (params, cb) ->
    _trashcan_method_helper('restore', params, cb)


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

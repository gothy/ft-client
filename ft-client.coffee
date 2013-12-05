base_url = 'http://filestrash.com/api/v1'

token = null

class ApiError extends Error
    constructor: ->

class NetworkError extends Error
    constructor: ->


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

userInfo = (cb, params = {}) ->
    params.token = params.token || token
    $.ajax
        url: "#{base_url}/user/login"
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

fileUpload = (params, cb, progress_cb) ->
    params.token = params.token || token
    $.ajax
        url: '#{base_url}/file/upload'
        data: params
    .done (data) =>
        data = JSON.parse(data)
        response = data.response
        if data.status is 200
            if response.upload_url
                _do_file_upload(params, upload_url, cb, progress_cb)
            else
                if cb && typeof cb == 'function' then cb(null, data.response.file)
        else
            if cb && typeof cb == 'function'
                cb(new ApiError("#{data.status}: #{data.details}"))
    .fail (jqxhr, status) =>
        if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

_do_file_upload = (params, upload_url, cb, progress_cb) ->
    form_data = new FormData()
    form_data.append("file", params.file)
    form_data.append("token", token)
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
        url: '#{base_url}/file/#{method}'
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
    # params.token = params.token || token
    # $.ajax
    #     url: '#{base_url}/file/rename'
    #     data: params
    # .done (data) =>
    #     data = JSON.parse(data)
    #     response = data.response
    #     if data.status is 200
    #         if cb && typeof cb == 'function' then cb(null, data.response.file)
    #     else
    #         if cb && typeof cb == 'function'
    #             cb(new ApiError("#{data.status}: #{data.details}"))
    # .fail (jqxhr, status) =>
    #     if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

fileDelete = (params, cb) ->
    _file_method_helper('delete', params, cb)
    # params.token = params.token || token
    # $.ajax
    #     url: '#{base_url}/file/delete'
    #     data: params
    # .done (data) =>
    #     data = JSON.parse(data)
    #     response = data.response
    #     if data.status is 200
    #         if cb && typeof cb == 'function' then cb(null, data.response)
    #     else
    #         if cb && typeof cb == 'function'
    #             cb(new ApiError("#{data.status}: #{data.details}"))
    # .fail (jqxhr, status) =>
    #     if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

fileCopy = (params, cb) ->
    _file_method_helper('copy', params, cb)
    # params.token = params.token || token
    # $.ajax
    #     url: '#{base_url}/file/copy'
    #     data: params
    # .done (data) =>
    #     data = JSON.parse(data)
    #     response = data.response
    #     if data.status is 200
    #         if cb && typeof cb == 'function' then cb(null, data.response)
    #     else
    #         if cb && typeof cb == 'function'
    #             cb(new ApiError("#{data.status}: #{data.details}"))
    # .fail (jqxhr, status) =>
    #     if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

fileMove = (params, cb) ->
    _file_method_helper('move', params, cb)
    # params.token = params.token || token
    # $.ajax
    #     url: '#{base_url}/file/move'
    #     data: params
    # .done (data) =>
    #     data = JSON.parse(data)
    #     response = data.response
    #     if data.status is 200
    #         if cb && typeof cb == 'function' then cb(null, data.response)
    #     else
    #         if cb && typeof cb == 'function'
    #             cb(new ApiError("#{data.status}: #{data.details}"))
    # .fail (jqxhr, status) =>
    #     if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))


_fldr_ops = ['info', 'content', 'create', 'rename']
_folder_method_helper = (method, params, cb) ->
    params.token = params.token || token
    $.ajax
        url: '#{base_url}/folder/#{method}'
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

# TODO: how it's different about subfolder list from folderContent?
folderInfo = (params, cb) ->
    _folder_method_helper('info', params, cb)
    # params.token = params.token || token
    # $.ajax
    #     url: '#{base_url}/folder/info'
    #     data: params
    # .done (data) =>
    #     data = JSON.parse(data)
    #     response = data.response
    #     if data.status is 200
    #         if cb && typeof cb == 'function' then cb(null, data.response.folder)
    #     else
    #         if cb && typeof cb == 'function'
    #             cb(new ApiError("#{data.status}: #{data.details}"))
    # .fail (jqxhr, status) =>
    #     if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

folderContent = (params, cb) ->
    _folder_method_helper('content', params, cb)
    # params.token = params.token || token
    # $.ajax
    #     url: '#{base_url}/folder/info'
    #     data: params
    # .done (data) =>
    #     data = JSON.parse(data)
    #     response = data.response
    #     if data.status is 200
    #         if cb && typeof cb == 'function' then cb(null, data.response.folder)
    #     else
    #         if cb && typeof cb == 'function'
    #             cb(new ApiError("#{data.status}: #{data.details}"))
    # .fail (jqxhr, status) =>
    #     if cb && typeof cb == 'function' then cb(new NetworkError("#{jqxhr.status}: #{status}"))

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


window.FTClient = FTClient = {
    # internal stuff, can monkeypatch thought
    _token: token
    _base_url: base_url
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
}

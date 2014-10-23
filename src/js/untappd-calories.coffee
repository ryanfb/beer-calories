untappd_config =
	client_id: '6CEC661CC1E87C1BE1B7D7FE30865F670AF6218B'
	redirect_url: window.location.href.replace("#{location.hash}",'')
	response_type: 'token'

untappd_auth_url = ->
  "https://untappd.com/oauth/authenticate/?#{$.param(untappd_config)}"

expires_in_to_date = (expires_in) ->
  cookie_expires = new Date
  cookie_expires.setTime(cookie_expires.getTime() + expires_in * 1000)
  return cookie_expires

set_cookie = (key, value, expires_in) ->
  cookie = "#{key}=#{value}; "
  cookie += "expires=#{expires_in_to_date(expires_in).toUTCString()}; "
  cookie += "path=#{window.location.pathname.substring(0,window.location.pathname.lastIndexOf('/')+1)}"
  document.cookie = cookie

delete_cookie = (key) ->
  set_cookie key, null, -1

get_cookie = (key) ->
  key += "="
  for cookie_fragment in document.cookie.split(';')
    cookie_fragment = cookie_fragment.replace(/^\s+/, '')
    return cookie_fragment.substring(key.length, cookie_fragment.length) if cookie_fragment.indexOf(key) == 0
  return null

# write an Untappd access token into a cached cookie
set_access_token_cookie = (params, callback) ->
  if params['state']?
    console.log "Replacing hash with state: #{params['state']}"
    history.replaceState(null,'',window.location.href.replace("#{location.hash}","##{params['state']}"))
  if params['access_token']?
  	console.log("Got access token: #{params['access_token']}")
  	set_cookie('access_token',params['access_token'],31536000)
  	callback(params) if callback?
  else
  	callback(params) if callback?

# parse URL hash parameters into an associative array object
parse_query_string = (query_string) ->
  query_string ?= location.hash.substring(1)
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

# filter URL parameters out of the window URL using replaceState 
# returns the original parameters
filter_url_params = (params, filtered_params) ->
  rewritten_params = []
  filtered_params ?= ['access_token','expires_in','token_type']
  for key, value of params
    unless _.include(filtered_params,key)
      rewritten_params.push "#{key}=#{value}"
  if rewritten_params.length > 0
    hash_string = "##{rewritten_params.join('&')}"
  else
    hash_string = ''
  history.replaceState(null,'',window.location.href.replace("#{location.hash}",hash_string))
  return params

# http://beercritic.wordpress.com/beer-calorie-cheatsheet/
calculate_calories = (abv, floz = 12) ->
	return (floz * abv / 60 * 150)

build_untappd_calories = (params) ->
	if get_cookie 'access_token'
		console.log 'Success!'
	else
		console.log 'Not logged in, redirecting'
		window.location = untappd_auth_url()

$(document).ready ->
  set_access_token_cookie(filter_url_params(parse_query_string()), build_untappd_calories)
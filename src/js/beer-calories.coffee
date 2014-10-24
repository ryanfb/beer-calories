untappd_config =
  client_id: '6CEC661CC1E87C1BE1B7D7FE30865F670AF6218B'
  redirect_url: 'https://ryanfb.github.io/beer-calories/'
  response_type: 'token'

untappd_api_url = 'https://api.untappd.com/v4'

untappd_auth_url = ->
  "https://untappd.com/oauth/authenticate/?#{$.param(untappd_config)}"

# write an Untappd access token into localStorage
set_access_token = (params, callback) ->
  if params['state']?
    console.log "Replacing hash with state: #{params['state']}"
    history.replaceState(null,'',window.location.href.replace("#{location.hash}","##{params['state']}"))
  if params['access_token']?
    console.log("Got access token: #{params['access_token']}")
    localStorage['access_token'] = params['access_token']
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
  return Math.round(floz * abv / 60 * 150)

update_calories = (serving_size) ->
  $('#calories').text(calculate_calories($('#abv').val(), serving_size))

build_untappd_calories = (params) ->
  $('#abv_form').submit (event) ->
    event.preventDefault()
  $('#serving_size').find('a').on 'tap', (event) ->
    update_calories($(event.target).data('serving-size'))
  $('#abv').change ->
    update_calories($('#serving_size .ui-btn-active').first().data('serving-size'))
  if localStorage['access_token']
    $('#untappd_button').append('<a id="fill_abv" href="#">Fill ABV from last Untappd checkin</a>')
    $('#fill_abv').click ->
      $('#abv').val($('#last_abv').text())
      $('#abv').change()
    $.ajax "#{untappd_api_url}/user/checkins/?access_token=#{localStorage['access_token']}&limit=1",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      success: (data) ->
        console.log data
        beer = data['response']['checkins']['items'][0]['beer']
        $('#content').append('<div id="last_checkin" align="center" id="ui-body-untappd" class="ui-body ui-body-a ui-corner-all">')
        $('#last_checkin').append("<p>Last Untappd checkin: #{beer['beer_name']} (<span id=\"last_abv\">#{beer['beer_abv']}</span>% ABV)</p>")
  else
    $('#untappd_button').append("<a href=\"#{untappd_auth_url()}\">Log in to Untappd</a>")

$(document).ready ->
  set_access_token(filter_url_params(parse_query_string()), build_untappd_calories)
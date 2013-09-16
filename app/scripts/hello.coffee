$ ->
  $.ajax
    url: 'user'
    dataType: "json"
    success: (data) ->
      $("#logged-in-screen").show().find('.email').text(data.email)
    error: () ->
      $("#login-screen").show()


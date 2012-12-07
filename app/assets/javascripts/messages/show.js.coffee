$(document).ready ->
  $(".replytext").autosize()
  setTimeout (->
    $(".replytext").focus()
  ), 700
  $(".announce").scrollToFixed
    marginTop: 54
    preFixed: ->
      $(this).addClass "namefloat"

    postFixed: ->
      $(this).removeClass "namefloat"

  $(".replybox").scrollToFixed
    bottom: 0
    limit: $(".replybox").offset().top
    preFixed: ->
      $(this).addClass "replyfloat"

    postFixed: ->
      $(this).removeClass "replyfloat"

  $("html, body").animate
    scrollTop: $(document).height()
  , 1000

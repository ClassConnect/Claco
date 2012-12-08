$ ->
  
  # autocomplete for grades and subjects
  split = (val) ->
    val.split /,\s*/
  extractLast = (term) ->
    split(term).pop()
  $("#city").autocomplete
    source: (request, response) ->
      $.ajax
        url: "http://ws.geonames.org/searchJSON"
        dataType: "jsonp"
        data:
          featureClass: "P"
          style: "full"
          maxRows: 12
          name_startsWith: request.term

        success: (data) ->
          response $.map(data.geonames, (item) ->
            label: item.name + ((if item.adminName1 then ", " + item.adminName1 else "")) + ", " + item.countryName
            value: item.name
            lat: item.lat
            lng: item.lng
          )


    minLength: 2
    autoFocus: true
    select: (event, ui) ->
      $("#city").hide()
      $(".fulldiv").show()
      (if ui.item then $("#fulllocation").val(ui.item.label) else $("#fulllocation").val(@value))
      $("#lng").val ui.item.lng
      $("#lat").val ui.item.lat

    open: ->

    close: ->

  $(".biotext").keypress (e) ->
    tval = $(".biotext").val()
    tlength = tval.length
    set = 180
    remain = parseInt(set - tlength)
    $(".remain").text remain
    $(".biotext").val (tval).substring(0, tlength - 1)  if remain <= 0 and e.which isnt 0 and e.charCode isnt 0

  
  # don't navigate away from the field on tab when selecting an item
  
  # delegate back to autocomplete, but extract the last term
  
  # prevent value inserted on focus
  
  # remove the current input
  
  # add the selected item
  
  # add placeholder to get the comma-and-space at the end
  $("#grades").bind("keydown", (event) ->
    event.preventDefault()  if event.keyCode is $.ui.keyCode.TAB and $(this).data("autocomplete").menu.active
  ).autocomplete(
    minLength: 0
    autoFocus: true
    delay: 0
    source: (request, response) ->
      response $.ui.autocomplete.filter(grade_data, extractLast(request.term))

    focus: ->
      false

    select: (event, ui) ->
      terms = split(@value)
      terms.pop()
      terms.push ui.item.title
      terms.push ""
      @value = terms.join(", ")
      false
  ).data("autocomplete")._renderItem = (ul, item) ->
    $("<li></li>").data("item.autocomplete", item).append("<a style='padding-left:5px'>" + item.title + "</a>").appendTo ul

  
  # don't navigate away from the field on tab when selecting an item
  
  # delegate back to autocomplete, but extract the last term
  
  # prevent value inserted on focus
  
  # remove the current input
  
  # add the selected item
  
  # add placeholder to get the comma-and-space at the end
  $("#subjects").bind("keydown", (event) ->
    event.preventDefault()  if event.keyCode is $.ui.keyCode.TAB and $(this).data("autocomplete").menu.active
  ).autocomplete(
    minLength: 0
    autoFocus: true
    delay: 0
    source: (request, response) ->
      response $.ui.autocomplete.filter(subject_data, extractLast(request.term))

    focus: ->
      false

    select: (event, ui) ->
      terms = split(@value)
      terms.pop()
      terms.push ui.item.title
      terms.push ""
      @value = terms.join(", ")
      false
  ).data("autocomplete")._renderItem = (ul, item) ->
    $("<li></li>").data("item.autocomplete", item).append("<a style='padding-left:5px'>" + item.title + "</a>").appendTo ul

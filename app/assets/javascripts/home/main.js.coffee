$(document).ready ->
  $("#newbinder").click ->
    $.facebox div: "#addbinder-form"
    $("#facebox .firstfocus").focus()
    $("#facebox .pub_on").iphoneStyle
      checkedLabel: "Public"
      uncheckedLabel: "Private"

    
    # set the form handler
    $("#facebox .bodcon").submit ->
      serData = $("#facebox .bodcon").serialize()
      fbFormSubmitted()
      $.ajax
        type: "POST"
        url: username + "/portfolio"
        dataType: "json"
        data: serData
        success: (retData) ->
          if retData["success"] is 1
            window.location = retData["data"]
          else
            fbFormRevert()
            showFormError retData["data"]

      false

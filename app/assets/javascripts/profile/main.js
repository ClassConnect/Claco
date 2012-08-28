dontmove = false;

$(document).ready(function() {

  $('#messbtn').click(function() {
    popForm('message-form', $(this));
  });

	$('.nav-tabs a').click(function() {
		$(".tabswap").hide();
		$($(this).attr("href")).show();
		$('.active').removeClass('active');
		$(this).parent().addClass('active');
		return false;
	});

	// click on box, redirect
  $('.content-item').click(function() {

  	if (dontmove === false) {
  		document.location = $(this).find('.titler a').attr("href");
  	}

  });


  // set all of the items that won't activate pjax on click
  $('.drop-tog, .linkster, .lastupdate').click(function() {
    dontmove = true;
  });



	$('#subbtn').click(function() {
		var subtype = ' ';
		// new subscription
		if ($(this).hasClass("btn-primary")) {
			$(this).removeClass("btn-primary");
			$(this).addClass("btn-danger");
			$(this).find('.upme').text('Unsubscribe');
			subtype = 'subscribe';
		} else {
			$(this).addClass("btn-primary");
			$(this).removeClass("btn-danger");
			$(this).find('.upme').text('Subscribe');
			subtype = 'unsubscribe';
		}

		$.ajax({
            url: location.protocol+'//'+location.host+location.pathname + '/' + subtype,
            data: '',
            type: 'put',
            success: function(data) {
              // if the data isn't success (aka "1")
              if (data != '1') {
                alert(data);
              }

			}
		});
	});


	$('#collbtn').click(function() {
		// new colleague request
		if ($(this).attr("disabled") == null) {
			$(this).attr("disabled", "disabled");
			$(this).find('.upme').text(' Request sent ');

			$.ajax({
                url: location.protocol+'//'+location.host+location.pathname + '/add',
                data: '',
                type: 'put',
                success: function(data) {
                  // if the data isn't success (aka "1")
                  if (data != '1') {
                    alert(data);
                  }

				}
			});


		}
	});







	// for our modification actions
  $('.modaction').click(function() {
    // if we're doing a rename
    if ($(this).attr('id') == 'rename-act') {
      popForm('rename-form', $(this).parent().parent().parent().parent().parent());

    } else if ($(this).attr('id') == 'delete-act') {
      popForm('delete-form', $(this).parent().parent().parent().parent().parent());

    } else if ($(this).attr('id') == 'copy-act') {
      popForm('copy-form', $(this).parent().parent().parent().parent().parent());

    } else if ($(this).attr('id') == 'move-act') {
      popForm('move-form', $(this).parent().parent().parent().parent().parent());

    }


  });





});













// here are the popup form helpers
function popForm(formID, obje) {
  // fire the open event for facebox
  jQuery.facebox({ div: '#' + formID });
  //$("#facebox").find('.firstfocus').focus();
  setTimeout(function() {$("#facebox").find('.firstfocus').focus();},100);

  // extended if to handle the different form types
  // if we're renaming a piece of content
  if (formID == 'rename-form') {

    // preset the title
    var contitle = obje.find('.titler a').text();
    $("#facebox").find('.rename-title').val(contitle);
    $("#facebox").find('.conid').val( obje.attr("id") );

    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      newTitle = $("#facebox").find('.rename-title').val();
      fbFormSubmitted();

      $.ajax({
        type: "PUT",
        url: obje.find('.titler a').attr("href") + "/rename",
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            closefBox();
            obje.find('.titler a').text(newTitle);
            setTimeout(function() {obje.effect('highlight');},100);

          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler

  ////////// if this is the delete form
  } else if (formID == 'delete-form') {


    $("#facebox").find('.conid').val( obje.attr("id") );

    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      fbFormSubmitted();


      $.ajax({
        type: "DELETE",
        url: obje.find('.titler a').attr("href"),
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            closefBox();
            obje.css('opacity', 1).slideUp(500).animate({ opacity: 0 },{ queue: false, duration: 500});

          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler




  ////////// if this is the delete form
  } else if (formID == 'message-form') {


    $("#facebox").find('.conid').val( obje.attr("id") );
    $('.repbox').autosize();

    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      fbFormSubmitted();



      $.ajax({
        type: "POST",
        url: location.protocol+'//'+location.host+location.pathname + '/message',
        data: serData,
        success: function(retData) {
          if (retData == 1) {

            initAsyc('<img src=\'/assets/success.png\' style=\'float:left; margin-right:15px;\' /> Message sent successfully!');
            setTimeout(function() {destroyAsyc();},1500);

            closefBox();


          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler



  }

}
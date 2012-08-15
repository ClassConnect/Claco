dontmove = false;

$(document).ready(function() {

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
	        data: 'xyz',
	        type: 'post',
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
		        url: location.protocol+'//'+location.host+location.pathname + '/URLHERE',
		        data: 'xyz',
		        type: 'post',
		        success: function(data) {
		          // if the data isn't success (aka "1")
		          if (data != '1') {
		            alert(data);
		          }

		        }
		    });


		}
	});

});
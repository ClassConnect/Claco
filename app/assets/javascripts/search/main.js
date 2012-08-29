$(document).ready(function() {

	$('.subbtn').click(function() {
		// new subscription
		$(this).after('<div>Subscribed!</div>');


		$.ajax({
            url: location.protocol+'//'+location.host+location.pathname + '/' + "varhere",
            data: '',
            type: 'put',
            success: function(data) {
              // if the data isn't success (aka "1")
              if (data != '1') {
                alert(data);
              }

			}
		});

		$(this).remove();


		return false;
	});


});
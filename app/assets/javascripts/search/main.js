$(document).ready(function() {

	$('.subbtn').click(function() {
		// new subscription
		$(this).after('<div style="margin-right:5px;float:right;font-weight:bolder;color:#555">✓ Subscribed!</div>');


		$.ajax({
            url: $(this).parent().parent().find('.bigtitle a:first').attr("href") + '/subscribe/',
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
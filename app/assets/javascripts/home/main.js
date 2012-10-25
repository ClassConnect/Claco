$(document).ready(function() {

	$('#newbinder').click(function() {

		$.facebox({ div: '#addbinder-form' });

		$("#facebox .firstfocus").focus();

		$('#facebox .pub_on').iphoneStyle({
			checkedLabel: 'Public',
			uncheckedLabel: 'Private'
		});


		// set the form handler
		$('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      fbFormSubmitted();

      $.ajax({
        type: "POST",
        url: username + "/portfolio",
        dataType: "json",
        data: serData,
        success: function(retData) {
          if (retData["success"] == 1) {
            window.location = retData["data"];
          } else {
            fbFormRevert();
            showFormError(retData["data"]);
          }
  			}
      });
      return false;
		});
	});
});
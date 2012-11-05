$(document).ready(function() {
  // activate binders-list tabs
  $('#binder-tabs a').click(function /*toggle*/(_target) {
    // coerce target & source into jQuery objects
    var _source = $(this),
        _target = jQuery('[data-href='+_source.data('target')+']');
        // target element has data-href property
    
    // toggle source
    _source
      .parent('li')
      .siblings('li')
      .removeClass('active');
      // ! this shouldn't be here; ask diwank to fix it
    _source
      .parent('li')
      .addClass('active');
    
    // toggle target
    _target
      .siblings('[data-href]')
      .addClass('hidden');

    _target.removeClass('hidden');

    return _target;
  });

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
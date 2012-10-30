/**
* @authors: diwank
* @status: stable / not well documented
*/
$(document).ready(function(){
	var queryMap = getQueryHash(),			    // get query params
		changeBinder = $.Event("changeBinder");

	$('a.descToggle').click(function /*descriptionToggle*/ (){
		$('div.description')
			.show()
			.find('textarea')
			.focus();

		$(this).hide();
		return false;
	});

	$.each(queryMap, function /*prefillFields*/ (k, v){
		$('form *[name='+k+']').val(v);

		if(queryMap.body != '')
			$('a.descToggle').click();
		
		$('form').trigger('change');
	});


	$('div.dir').on('changeBinder', function /*updateFormAction*/ (){
		var binderUrl = $(this).attr('turl');
		$('input[name=binderUrl]').val(binderUrl);

		$('form#post')
			.attr('action', binderUrl + '/createcontent')
			.trigger('change');
	});

	function validate (form){
		var rules = {};						// validation rules
		rules.required =
			['webtitle', 'weblink', 'binderUrl'];

		form.find('button[type=submit]')
			.removeAttr('disabled');
		
		$(rules.required).each(function(i, elem){
			var field = form.find('*[name='+elem+']');

			if(!field.val()){
				field.focus();
				form.find('button[type=submit]')
					.attr('disabled','disabled');
			}
		});
	}

	$('form#post').change(function /*validateForm*/ (){
		validate($(this));
	});

	function message(type, text) {
		$('form#post, div.fol-picker').hide();

		$('#msgBox')
			.addClass('alert-'+type)
			.show()
			.find('h4').html(type)
			.siblings('p').html(text);
	}

	$('form#post').submit(function /*ajaxRequester*/ (){
		$('button[type=submit]')
			.html('Please wait')
			.attr('disabled','disabled');

		$.ajax({
				url: $('form#post').attr('action'),
				data: $('form#post').serialize(),
				type: "POST"
			})
			.done(function /*showSuccessMsg*/ (data, status){
				message('success',
					'The link has been snapped to your binder! <br> Redirecting you back to the site.');
				window.setTimeout(window.close, 1600);
			})
			.fail(function /*showErrorMsg*/ (data, status){
				message('error',
					'Something went wrong.. <br> Resetting.');
				window.setTimeout(window.location.reload(), 1600);
			});

		return false;
	});
});
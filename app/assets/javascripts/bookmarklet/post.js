$(document).ready(function(){
	var queryMap = getQueryHash();			// get query params
	var changeBinder = $.Event("changeBinder");	// create custom event

	$('a.descToggle').click(function(){		// description toggle button
		$('div.description').show().find('textarea').focus();
		$(this).hide();
		return false;
	});

	$.each(queryMap, function (k, v){		// prefill fields
		$('form *[name='+k+']').val(v);
		if(queryMap.body != ''){
			$('a.descToggle').click();
		}
		$('form').trigger('change');
	});

	$('div.dir').on('changeBinder', function (){
		var binderUrl = $(this).attr('turl');
		$('input[name=binderUrl]').val(binderUrl);
		$('form#post').attr('action', binderUrl + '/createcontent')
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

	$('form#post').change(function (){			// validate form
		validate($(this));
	});

	function message(type, text) {
		$('form#post, div.fol-picker').hide();
		$('#msgBox').addClass('alert-'+type)
			.show()
			.find('h4').html(type)
			.siblings('p').html(text);
	}

	$('form#post').submit(function(){
		$('button[type=submit]')
			.html('Please wait')
			.attr('disabled','disabled');
		$.ajax({
			url: $('form#post').attr('action'),
			data: $('form#post').serialize(),
			type: "POST"
			})
			.done(function (data, status){
				message('success',
					'The link has been snapped to your binder! <br> Redirecting you back to the site.');
				window.setTimeout(window.close, 1600);
			})
			.fail(function (data, status){
				message('error',
					'Something went wrong.. <br> Resetting.');
				window.location.reload();
			});
		return false;
	});
});
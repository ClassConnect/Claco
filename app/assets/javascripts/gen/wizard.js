// save to cookie
function wiz2cook() {
	$.cookie("startdata", JSON.stringify($(".brand").data()));
}

// read from cookie
function cook2wiz() {
	$(".brand").data(JSON.parse($.cookie("startdata")));
}



function wizardFocus(num) {
	$(".brand").data('init', {on:true});


	// set the current path
	$(".brand").data('path', {val:num});

	// remove any guiders that may be loaded
	$(".guider").remove();


	$(".brand").data('' + num + '', {step:1});


	if (num == 4) {
		 $('html, body').animate({ scrollTop: 200 }, 500);
	}



	// save the current data to the cookie
	wiz2cook();
	// initialize the wizard
	startWizard();
}








// start up the wizard (may fire guideDirect if not on right page)
function startWizard() {
	// if this is the home view, cross off completed tasks
	if (page == 'home#index' && loggedin === true) {
		if ($(".brand").data('1').step === 0) {
			$("#task1").addClass('crossout');
		}

		if ($(".brand").data('2').step === 0) {
			$("#task2").addClass('crossout');
		}



		if ($(".brand").data('3').step === 0) {
			$("#task3").addClass('crossout');
		}



		if ($(".brand").data('4').step === 0) {
			$("#task4").addClass('crossout');
		}

	}


	var path = $(".brand").data('path').val;


	// if this is an edit profile path
	if (path == 1) {
		if ($(".brand").data('1').step === 1) {

			// if we're on the teacher profile
			if (page == 'teachers#show') {

				// we have now moved on to step 2
				$(".brand").data('1', {step:2});

				guiders.createGuider({
				  buttons: [{name: "Next", onclick: guiders.next}],
				  description: "Your lessons, curriculum, content and information will be showcased here in your portfolio for the world to see. Make it easy for colleagues and other teachers to find you and your work by filling out your profile!",
				  id: "first",
				  next: "second",
				  title: "This is your profile.",
				  width: 450
				}).show();

				guiders.createGuider({
				  attachTo: '#editinfobtn',
				  id: "second",
				  position: 6,
				  title: "Click 'Edit Info'",
				  width: 200,
				  xButton: true
				});


			} else {
				guiders.createGuider({
				  attachTo: "#namester",
				  position: 6,
				  title: "Click your name!",
				  width: 200,
				  xButton: true
				}).show();

			}



		} else if ($(".brand").data('1').step === 2) {

			// if we're on the edit profile page
			if (page == 'teachers#editinfo') {
				$(".brand").data('1', {step:0});
			} 

			
		}





	// if this is the create binder path
	} else if (path == 2) {
		// we still need to click the button
		if ($(".brand").data('2').step === 1) {

			// if we're on the home page
			if (page == 'home#index' && loggedin === true) {

				// set this as complete
				$(".brand").data('2', {step:0});

				// set click handler for new binder
				$('#newbinder').click(function() {
					guiders.hideAll();
				});


				guiders.createGuider({
				  buttons: [{name: "Next"}],
				  description: '<iframe width="650" height="400" src="http://www.youtube.com/embed/jcVPbSMOkRg?vq=hd720" frameborder="0" allowfullscreen></iframe>',
				  id: "first",
				  next: "second",
				  title: "Store websites, videos, and files in binders.",
				  width: 650
				}).show();



				guiders.createGuider({
				  attachTo: "#newbinder",
				  position: 6,
				  title: "Click 'Create a new binder'",
				  width: 300,
				  id: "second",
				  xButton: true
				});





			} else {
				guiders.createGuider({
				  attachTo: ".brand",
				  position: 6,
				  title: "Click here!",
				  width: 150,
				  xButton: true,
				  offset: {
			        top: null,
			        left: 50
			      },
				}).show();
			}


		}






	// if this is the subscription path
	} else if (path == 3) {
		// we still need to click the button
		if ($(".brand").data('3').step === 1) {

			// if we're on the home page
			if (page == 'home#index' && loggedin === true) {

				// set this as complete
				$(".brand").data('3', {step:0});




				guiders.createGuider({
				  buttons: [{name: "Close"}],
				  description: "<iframe width=\"650\" height=\"400\" src=\"http://www.youtube.com/embed/AaLT4qD0dMc?vq=hd720\" frameborder=\"0\" allowfullscreen></iframe>",
				  id: "first",
				  next: "second",
				  title: "Learn how to snap together your curriculum!",
				  width: 650
				}).show();



			}


		}






	// if this is the subscription path
	} else if (path == 4) {
		// we still need to click the button
		if ($(".brand").data('4').step === 1) {

			// if we're on the home page
			if (page == 'home#index' && loggedin === true) {

				// set this as complete
				$(".brand").data('4', {step:0});




				guiders.createGuider({
				  attachTo: ".findppl",
				  position: 12,
				  description: "Connect your social networks and we'll automatically subscribe you to your colleagues that are already on Claco! You can also browse and subscribe to the curriculum from top educators on Claco that you may not know yet.",
				  title: "Follow the work of your favorite educators",
				  width: 460,
				  xButton: true
				}).show();





			} else {
				guiders.createGuider({
				  attachTo: ".brand",
				  position: 6,
				  title: "Click here!",
				  width: 150,
				  xButton: true,
				  offset: {
			        top: null,
			        left: 50
			      },
				}).show();
			}


		}





	}





	// save any changes to the cookie
	wiz2cook();

}








$(document).ready(function() {
	$(".brand").data('init', {on:false});
	// get the cookie data
	cook2wiz();

	if ($(".brand").data('init').on === true) {
		startWizard();
	} else {
		$(".brand").data('1', {step:99});
		$(".brand").data('2', {step:99});
		$(".brand").data('3', {step:99});
		$(".brand").data('4', {step:99});
	}




	// if we're killing the wizard
	// ...yer a wizard hary
	$('.finishbtn').click(function() {
		$.ajax({
	        url: '/done',
	        data: 'valid=1',
	        type: 'post',
	        success: function(data) {
	          // do nothing
	        }
	    });

		$('.starting-section').css('opacity', 1).slideUp(400).animate({ opacity: 0 },{ queue: false, duration: 400});
		$('.findppl').css('opacity', 1).slideUp(400).animate({ opacity: 0 },{ queue: false, duration: 400});
	});


});
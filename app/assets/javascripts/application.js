// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs

$(document).ready(function() {
	$(".noclose").on("click", function(e){
	    e.stopPropagation();
	});

	$("#top-notch-btn").on("click", function(e){
		if (!$(".noclose").is(":visible")) {

			setTimeout(function() {$(".login-focus").focus();},100);

		}
	    
	});

});




function initAsyc(content) {
	$('.async-pop').html(content).slideDown(100);
}

function destroyAsyc() {
	$('.async-pop').slideUp(100);
}






function htmlEncode(value){
    if (value) {
        return jQuery('<div />').text(value).html();
    } else {
        return '';
    }
}
 
function htmlDecode(value) {
    if (value) {
        return $('<div />').html(value).text();
    } else {
        return '';
    }
}


// close facebox
function closefBox() {
	jQuery(document).trigger('close.facebox');
}


// facebox form helpers
function fbFormActLoader() {
	$("input").blur();
	$("#facebox").find('.showloader').append('<img src="/assets/miniload.gif" id="tempload" style="float:left;margin-right:10px;margin-top:4px" />');
}

function fbFormActRevert() {
	$("#tempload").remove();
}

function fbFormDisable(formID) {
	$('#facebox :input').attr('disabled', true);
 
	$('#facebox :submit').attr('disabled', true);
}

function fbFormEnable(formID) {
	$('#facebox :input').attr('disabled', false);
 
	$('#facebox :submit').attr('disabled', false);
}

function fbFormSubmitted() {
	fbFormActLoader();
	fbFormDisable();
}

function fbFormRevert() {
	fbFormActRevert();
	fbFormEnable();
}

function showFormError(data) {
	$("#facebox .errorBox").html(data).show();
}
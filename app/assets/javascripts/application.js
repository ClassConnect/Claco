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
//= require jquery.pjax

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





// okay so now lets build the picker functions
function togglePicker(tObj) {
	tObj = $(tObj);
	if (tObj.parent().find('.pickerpane').is(":visible")) {
		tObj.parent().find('.pickerpane').hide();
	} else {
		tObj.parent().find('.pickerpane').show();
	}
}


function togglePickFolder(fObj) {
	var childs = $(fObj).parent().find('.dirWrap:first');
	// if we've loaded the children already
	if (childs.html() != '') {

		// if it's visible, hide it
		if (childs.is(":visible")) {
			$(fObj).removeClass('arrow-down').addClass('arrow-right');
            childs.hide();
		} else {
			$(fObj).addClass('arrow-down').removeClass('arrow-right');
            childs.show();
		}

	// load the children
	} else {
		$(fObj).parent().find(".dirWrap").html('Loading...').show();
		$(fObj).addClass('arrow-down').removeClass('arrow-right');
		

		$.getJSON($(fObj).parent().attr('turl') + '.json', function(data) {

			$(fObj).parent().find(".dirWrap").html('');

			$.each(data, function(key, val) {
				if (val['type'] == 1) {
					$(fObj).parent().find(".dirWrap").append('<div class="dir" folid="' + val['id'] + '" turl="' + val['path'] + '">\
                <div class="arrow-right" onclick="togglePickFolder(this)"></div>\
                <span class="dirtitle" onclick="selectPickFolder(this)">\
                  <img src="/assets/binders/folder.png" class="foldicon" />\
                  ' + val['name'] + '\
                </span>\
                <div class="dirWrap"></div>\
              </div>');
				}
			});


			if ($(fObj).parent().find(".dirWrap").html() == '') {
				$(fObj).parent().find(".dirWrap").html('No folders found here');
			}
		});

	}

}





function selectPickFolder(fObj) {
	var folid = $(fObj).parent().attr('folid');
	var text = $(fObj).text();

	$(fObj).closest(".bndr").parent().parent().find('.togbar').find('.chosenTitle').html(text);
	$(fObj).closest(".bndr").parent().parent().find('.togbar').find('.chosenOne').val(folid);
	$(fObj).closest(".pickerpane").hide();

}
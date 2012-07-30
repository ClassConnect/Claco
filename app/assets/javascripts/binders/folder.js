
  /*
  $( ".content-item" ).draggable({
    revert: "invalid",
    distance: 20,
    zIndex: 99999
  });

  $( ".content-list" ).sortable();*/
hovBool = false;
isDropped = false;
noteClick = false;
noteInit = false;
scrollBottom = false;

$(document).ready(function() {

  // if we have edit permissions, enable editing functionality
  if (isEditable === true) {
    editInit();
  }


});


$(document).on('pjax:start', function() {
  if (scrollBottom === false) {
    $('html, body').animate({ scrollTop: 0 }, 500);
  } else {
    scrollBottom = false;
  }
  
  // show loading
  initAsyc('<img src=\'/assets/miniload.gif\' style=\'float:left; margin-right:15px;margin-top:4px\' /> Loading...');

}).on('pjax:end',   function() {
  destroyAsyc();
  editInit();
});



// function for soft refreshes
function softRefresh() {
  $.pjax({
    url: location.protocol+'//'+location.host+location.pathname,
    container: '[data-pjax-container]',
    push: false
  });
}






function editInit() {
  noteInit = false;
  // for our modification actions
  $('.modaction').click(function() {
    // if we're doing a rename
    if ($(this).attr('id') == 'rename-act') {
      popForm('rename-form', $(this).parent().parent().parent().parent().parent());

    } else if ($(this).attr('id') == 'delete-act') {
      popForm('delete-form', $(this).parent().parent().parent().parent().parent());

    } else if ($(this).attr('id') == 'copy-act') {
      popForm('copy-form', $(this).parent().parent().parent().parent().parent());

    } else if ($(this).attr('id') == 'move-act') {
      popForm('move-form', $(this).parent().parent().parent().parent().parent());

    }


  });

  // init our folder autocomplete
  initAutoTagger('#folder-tags');


  $('#addtags-btn').click(function() {
    container = $(this).parent().parent().parent();

    if (container.hasClass('act-live')) {

      tagdata = tagsToJSON('#folder-tags');
      
      $.ajax({
        url: location.protocol+'//'+location.host+location.pathname + '/tags',
        data: tagdata,
        type: 'post',
        success: function(data) {
          // do nothing
        }
      });

      container.removeClass('act-live');
      $(this).removeClass('btn-primary savebtn').html('Add New');


      // how should we close this?
      if ($('.tags li').length > 0) {
        // we're doing a custom close up
        $('.tag-group').each(function(index) {
            if ($(this).find('.tags li').length == 0) {
              $(this).css('opacity', 1).slideUp(150).animate({ opacity: 0 },{ queue: false, duration: 150});
            }
        });


        $('.tagenter').css('opacity', 1).slideUp(150).animate({ opacity: 0 },{ queue: false, duration: 150});


      } else {
        container.find('.content-fill').css('opacity', 1).slideUp(150).animate({ opacity: 0 },{ queue: false, duration: 150});
      container.find('.fortags').css('opacity', 0).slideDown(150).animate({ opacity: 1 },{ queue: false, duration: 150});
      }
      



    } else {
      container.addClass('act-live');
      $(this).addClass('btn-primary savebtn').html('&nbsp;&nbsp;Save&nbsp;&nbsp;');


      // how should we open this?
      if ($('.tags li').length > 0) {
        // we're doing a custom open up
        $('.tag-group').each(function(index) {
            if ($(this).find('.tags li').length == 0) {
              $(this).css('opacity', 0).slideDown(150).animate({ opacity: 1 },{ queue: false, duration: 150});
            }
        });

        $('.tagenter').css('opacity', 0).slideDown(150).animate({ opacity: 1 },{ queue: false, duration: 150});


      } else {
        container.find('.fortags').css('opacity', 1).slideUp(150).animate({ opacity: 0 },{ queue: false, duration: 150});
      container.find('.content-fill').css('opacity', 0).slideDown(150).animate({ opacity: 1 },{ queue: false, duration: 150});
      }

      //setTimeout(function() {$("#tag-adder").focus();},150);

      //$('#tag-adder').focus();
    }


  });


  // if we click the notepad, open the editor
  $(".descbox").click(function() {
    if ($('.real-text').is(':visible') && noteClick == false) {

      if (noteInit == false) {
        // init notepad stuff
        editor = new wysihtml5.Editor("notearea", {
          toolbar:      "wysitoolbar",
          parserRules:  wysihtml5ParserRules
        });

        noteInit = true;
      }
      //$(editor.composer.element).html($('.real-text').html());

      $('.real-text').hide();
      $('.wysi-edit').show();
      editor.composer.element.focus();

    } else if (noteClick == true) {
      noteClick = false;

    }
  });

  // we're performing a save
  $(".save-wysi").click(function() {
      editor.composer.element.blur();
      $('.real-text').html($(editor.composer.element).html());
      $('.wysi-edit').hide();
      $('.real-text').show();
      noteClick = true;

      noteSon = { 'text': $(editor.composer.element).html() };

      $.ajax({
        url: location.protocol+'//'+location.host+location.pathname,
        data: noteSon,
        type: 'put',
        success: function(data) {
          // do nothing
        }
      });

  });





    $( ".content-list" ).sortable({
      refreshPositions: true,
      opacity: 0.90,
      distance: 15,
      start: function(event, ui) {
        $('.ui-sortable-placeholder').after('<div class="placeBorder">&nbsp;</div>');
      },
      change: function(event, ui) {
        $('.placeBorder').remove();
        $('.ui-sortable-placeholder').after('<div class="placeBorder">&nbsp;</div>');
      },
      stop: function(event, ui) {
        $('.placeBorder').remove();


        if (isDropped == false) {
          olist = [];
          // save these changes

          $('.content-item').each(function(index) {
            olist[index] = $(this).attr('id');

          });


          olist = { data: olist };

          $.ajax({
            url: location.protocol+'//'+location.host+location.pathname + "/reorder",
            data: olist,
            // post is the proper HTTP verb
            type: 'post',
            success: function(data) {
              // nothing
            }
          });

        } else {
          isDropped = false;

        }


      }
    });


    $( ".droppable" ).droppable({
      tolerance: "intersect",
      hoverClass: "dropperblue",
      over: function(event, ui) {
        hovBool = true;

         // insert new div element
        $('.ui-sortable-helper').after('<div class="dropper-tog"><div class="folder-preview">' + $('.ui-sortable-helper').find('.folder-preview').html() + '</div><div class="big-text">move to folder</div><div class="tricontain"><div class="fattie"></div><div class="pointy"></div></div></div>');

        $('body').bind('mousemove', function(e){
            $('.dropper-tog').css({
               left:  e.pageX,
               top:   e.pageY
            });
        });

        setTimeout('dropHover()', 200);

      },
      out: function(event, ui) {
        hovBool = false;

        $('.placeBorder').fadeIn(100);

        killHover();

        $('.ui-sortable-helper').animate({
          opacity: 1
        }, 200, function() {
          // Animation complete.
        });
        
      },
      drop: function( event, ui ) {
        // set the dropped variable
        isDropped = true;
        // post data to server
        sendData = { "target": $(this).attr("id") };
        $.ajax({
          url: $('.ui-sortable-helper').find('.titler a').attr("href") + "/move",
          data: sendData,
          type: 'put',
          success: function(data) {
            // do nothing
          }
        });

        $('body').unbind('mousemove');
        // find position and move the element
        pos1 = $(this).find('.folder-preview').offset();
        pos2 = $('.dropper-tog').find('.folder-preview').offset();
   
        topfin = pos1.top - pos2.top + 15;
        leftfin = pos1.left - pos2.left + 15;

        $('.dropper-tog').find('.folder-preview').css({position: 'absolute'}).animate({ top: topfin, left: leftfin }, 100);

        $('.dropper-tog').css('opacity', 1).animate({ opacity: 0.01 },{ queue: false, duration: 300});


        // okay, now lets remove the dropped folder from the DOM
        rmBx = $('.ui-sortable-helper');
        $('.ui-sortable-helper').animate({ opacity: 0.01 },{ queue: false, duration: 1}).slideUp(500);
        setTimeout('$(\'.dropper-tog\').remove(); rmBx.remove()', 400);
        //$('.ui-sortable-helper').remove();

      }
    });
}







// helper methods for drag & dropping files/folders
function dropHover() {

  if (hovBool == true) {

    $('.placeBorder').fadeOut(200);

    $('.dropper-tog').css('opacity', 0.01).animate({ opacity: 1 },{ queue: false, duration: 'fast'});

    // animate the fadeout of the actual div
    $('.ui-sortable-helper').css('opacity', 1).slideDown('fast').animate({ opacity: 0.01 },{ queue: false, duration: 'fast'});


  }

}


function killHover() {

  $('body').unbind('mousemove');
  $('.dropper-tog').remove();

}










// here are the popup form helpers
function popForm(formID, obje) {
  // fire the open event for facebox
  jQuery.facebox({ div: '#' + formID });
  //$("#facebox").find('.firstfocus').focus();
  setTimeout(function() {$("#facebox").find('.firstfocus').focus();},100);

  // extended if to handle the different form types
  // if we're renaming a piece of content
  if (formID == 'rename-form') {

    // preset the title
    var contitle = obje.find('.titler a').text();
    $("#facebox").find('.rename-title').val(contitle);
    $("#facebox").find('.conid').val( obje.attr("id") );

    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      newTitle = $("#facebox").find('.rename-title').val();
      fbFormSubmitted();

      $.ajax({
        type: "PUT",
        url: obje.find('.titler a').attr("href") + "/rename",
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            closefBox();
            obje.find('.titler a').text(newTitle);
            setTimeout(function() {obje.effect('highlight');},100);

          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler

  ////////// if this is the delete form
  } else if (formID == 'delete-form') {


    $("#facebox").find('.conid').val( obje.attr("id") );

    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      fbFormSubmitted();


      $.ajax({
        type: "DELETE",
        url: obje.find('.titler a').attr("href"),
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            closefBox();
            obje.css('opacity', 1).slideUp(500).animate({ opacity: 0 },{ queue: false, duration: 500});

          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler




  ////////// if this is the copy form
  } else if (formID == 'copy-form') {


    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      newTitle = $("#facebox").find('.rename-title').val();
      fbFormSubmitted();


      $.ajax({
        type: "PUT",
        url: obje.find('.titler a').attr("href") + "/copy",
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            closefBox();
            initAsyc('<img src=\'/assets/success.png\' style=\'float:left; margin-right:15px;\' /> Copied successfully!');
            setTimeout(function() {destroyAsyc();},1500);


          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler


  } else if (formID == 'move-form') {


    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      newTitle = $("#facebox").find('.rename-title').val();
      fbFormSubmitted();


      $.ajax({
        type: "PUT",
        url: obje.find('.titler a').attr("href") + "/move",
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            closefBox();
            initAsyc('<img src=\'/assets/success.png\' style=\'float:left; margin-right:15px;\' /> Moved successfully!');
            setTimeout(function() {destroyAsyc();},1500);
            obje.css('opacity', 1).slideUp(500).animate({ opacity: 0 },{ queue: false, duration: 500});


          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler




  } else if (formID == 'addweb-form') {

    titleCheck = false;

    $('#facebox .webtitle').focus(function() {
      if ($('#facebox .webtitle').val() == '' && $('#facebox .weblink').val() != '' && titleCheck == false) {
        $('#facebox .webtitle').val('Retrieving the title for you...');
        $('#facebox .webtitle').attr('disabled', 'disabled');
        fbFormActLoader();

        // get the title
        $.ajax({
          type: "POST",
          url: "/utils/fetchtitle",
          data: 'url=' + escape($('#facebox .weblink').val()),
          success: function(titleData) {
            titleCheck = true;
            $('#facebox .webtitle').val(titleData.substring(0, 55));
            $('#facebox .webtitle').removeAttr('disabled');
            $('#facebox .webtitle').focus();
            fbFormActRevert();
          },
          error: function(titleData) {
            titleCheck = true;
            $('#facebox .webtitle').val('');
            $('#facebox .webtitle').removeAttr('disabled');
            $('#facebox .webtitle').focus();
            fbFormActRevert();
          }
        });





      }

    });


    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      fbFormSubmitted();


      $.ajax({
        type: "POST",
        url: location.protocol+'//'+location.host+location.pathname + "/createcontent",
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            scrollBottom = true;
            softRefresh();
            closefBox();
            $('html, body').animate({ scrollTop: $(document).height() + 200 }, 700);


          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler




  } else if (formID == 'addfolder-form') {

    // set the form handler
    $('#facebox .bodcon').submit(function() {
      var serData = $("#facebox .bodcon").serialize();
      fbFormSubmitted();


      $.ajax({
        type: "POST",
        url: location.protocol+'//'+location.host+location.pathname + "/create",
        data: serData,
        success: function(retData) {
          if (retData == 1) {
            scrollBottom = true;
            softRefresh();
            closefBox();
            $('html, body').animate({ scrollTop: $(document).height() + 200 }, 700);


          } else {
            fbFormRevert();
            showFormError(retData);

          }

        }
        
      });

      return false;
    });
    // end of form handler




  } else if (formID == 'addfile-form') {


    // initialize the file upload functionality
    $('#facebox .filepick').fileupload({
        url: location.protocol+'//'+location.host+location.pathname + '/createfile',
        dataType: 'json',
        add: function (e, data) {
            data.submit();
        },
        start: function (e, data) {
          $('#facebox .file-upload-btn').after('<div class="tempprog" style="margin-left:50px;margin-top:5px"><img src="/assets/miniload.gif" style="float:left;margin-right:8px;margin-top:3px" /> <span style="font-size:14px;font-weight:bolder">Uploading your file...</span></div>');
          $('#facebox .file-upload-btn').hide();
        },
        done: function (e, data) {
            scrollBottom = true;
            softRefresh();
            closefBox();
            $('html, body').animate({ scrollTop: $(document).height() + 200 }, 700);
        },
        fail: function (e, data) {
          $('#facebox .tempprog').html('We had an issue uploading your file...<br /><strong>Please try again!</strong>');
          $('#facebox .file-upload-btn').show();
        }
    });



  }

}
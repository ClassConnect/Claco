$(document).ready(function() {

	$('.replytext').autosize();

	setTimeout(function() {$('.replytext').focus();},700);

	$('.announce').scrollToFixed( {
        marginTop: 54,
        preFixed: function() { 
          $(this).addClass('namefloat');
          
        },
        postFixed: function() {
          $(this).removeClass('namefloat');
          
        }
	});

	$('.replybox').scrollToFixed( {
        bottom:0,
        limit: $('.replybox').offset().top,
         preFixed: function() { 
          $(this).addClass('replyfloat');
          
        },
        postFixed: function() {
          $(this).removeClass('replyfloat');
          
        }
	});


	$('html, body').animate({ scrollTop: $(document).height() }, 1000);

});
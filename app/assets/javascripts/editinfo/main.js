$(function() {

		$( "#city" ).autocomplete({
			source: function( request, response ) {
				$.ajax({
					url: "http://ws.geonames.org/searchJSON",
					dataType: "jsonp",
					data: {
						featureClass: "P",
						style: "full",
						maxRows: 12,
						name_startsWith: request.term
					},
					success: function( data ) {
						response( $.map( data.geonames, function( item ) {
							return {
								label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
								value: item.name,
								lat: item.lat,
								lng: item.lng
							}
						}));
					}
				});
			},
			minLength: 2,
			autoFocus: true,
			select: function( event, ui ) {
				$("#city").hide();
				$(".fulldiv").show();
				ui.item ? $("#fulllocation").val(ui.item.label) :
				$("#fulllocation").val(this.value);
				$("#lng").val(ui.item.lng);
				$("#lat").val(ui.item.lat);
			},
			open: function() {
				
			},
			close: function() {
				
			}
		});


		$('.biotext').keypress(function(e) {
		    var tval = $('.biotext').val(),
		        tlength = tval.length,
		        set = 190,
		        remain = parseInt(set - tlength);
		    $('.remain').text(remain);
		    if (remain <= 0 && e.which !== 0 && e.charCode !== 0) {
		        $('.biotext').val((tval).substring(0, tlength - 1))
		    }
		});




		// autocomplete for grades and subjects
		function split( val ) {
			return val.split( /,\s*/ );
		}
		function extractLast( term ) {
			return split( term ).pop();
		}

		$( "#grades" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				minLength: 0,
				autoFocus: true,
				delay: 0,
				source: function( request, response ) {
					// delegate back to autocomplete, but extract the last term
					response( $.ui.autocomplete.filter(
						grade_data, extractLast( request.term ) ) );
				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					terms.push( ui.item.title );
					// add placeholder to get the comma-and-space at the end
					terms.push( "" );
					this.value = terms.join( ", " );
					return false;
				}
			}).data("autocomplete")._renderItem = function(ul, item) {
      return $( "<li></li>" )
      .data( "item.autocomplete", item )
      .append( "<a style='padding-left:5px'>" + item.title + "</a>")
      .appendTo( ul );
    };


    $( "#subjects" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				minLength: 0,
				autoFocus: true,
				delay: 0,
				source: function( request, response ) {
					// delegate back to autocomplete, but extract the last term
					response( $.ui.autocomplete.filter(
						subject_data, extractLast( request.term ) ) );
				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					terms.push( ui.item.title );
					// add placeholder to get the comma-and-space at the end
					terms.push( "" );
					this.value = terms.join( ", " );
					return false;
				}
			}).data("autocomplete")._renderItem = function(ul, item) {
      return $( "<li></li>" )
      .data( "item.autocomplete", item )
      .append( "<a style='padding-left:5px'>" + item.title + "</a>")
      .appendTo( ul );
    };




});
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
								value: item.name
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


});
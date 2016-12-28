var carousel = "";
$(document).ready(function() {;
  // Starting up carousel
  carousel = $('.carousel').carousel({
    interval: 9999999999999
  })

  // Rollover images
  $(function() {
    $('img[data-hover]').hover(function() {
      $(this).attr('tmp', $(this).attr('src')).attr('src', $(this).attr('data-hover')).attr('data-hover', $(this).attr('tmp')).removeAttr('tmp');
    }).each(function() {
      $('<img />').attr('src', $(this).attr('data-hover'));
    });;
  });

  // Slide selector
  $(".navbar .nav li a").click(function() {
    function clear_prods() {
      $(".navbar .nav li").each(function(){
        $(this).removeClass("active"); 
      });
    }
    carousel.unbind('slide');
    clear_prods();
    $(this).parent().addClass("active");
    carousel.carousel($(this).data()["slide"]);
    carousel.carousel('stop');
    carousel.bind('slide', function() {
      clear_prods();
      carousel.unbind('slide');
    });
  });

	if ($("#docs h2").length == 0){
		$("#docs-nav").remove();
	}else{
		$("<ul/>").insertAfter("#docs-nav");
		$("#docs h2").each(function(){
			$("<li><a href=\"#" + $(this).attr("id") + "\">" + $(this).text() + "</a></li>").appendTo("#docs-nav+ul");
		});
		if ($("#_rest_callbacks").length != 0){
			$('<ul id="_rest_callbacks_nav"/>').insertAfter('#docs-nav+ul a[href="#_rest_callbacks"]');
			$('#_rest_callbacks+div h3').each(function(){
				$("<li><a href=\"#" + $(this).attr("id") + "\">" + $(this).text() + "</a></li>").appendTo('#docs-nav+ul a[href="#_rest_callbacks"]+ul');
			});
		}
	}
});

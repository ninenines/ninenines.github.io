var carousel = "";
$(document).ready(function() {;
  // Starting up carousel
  carousel = $('.carousel').carousel({
    interval: 10000
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
});

$(document).ready(function() {
  $(".js-float-label-wrapper").FloatLabel();

  $(".js-float-option-wrapper").FloatSelect();

  $(document).on("keypress", function(e) {
    if(e.keyCode == 13) {
      e.preventDefault();
    }
  });

  $("input, select").focus(function() {
    $(this).parent(".js-float-label-wrapper ,js-float-option-wrapper").removeClass("error");
  })

  $("select").change(function() {
    if ($(this)[0].selectedIndex == 0) {
      $(".reason-description").hide(0);
    } else if($(this)[0].selectedIndex == 1) {
      $(".reason-description").show(0);
      $(".reason-description").children().hide(0);
      $(".reason-description-refund").show(0);
    } else if($(this)[0].selectedIndex == 2) {
      $(".reason-description").show(0);
      $(".reason-description").children().hide(0);
      $(".reason-description-return").show(0);
    } else if($(this)[0].selectedIndex == 3) {
      $(".reason-description").show(0);
      $(".reason-description").children().hide(0);
      $(".reason-description-exchange").show(0);
    } else if($(this)[0].selectedIndex == 4) {
      $(".reason-description").show(0);
      $(".reason-description").children().hide(0);
      $(".reason-description-repair").show(0);
    } else if($(this)[0].selectedIndex == 5) {
      $(".reason-description").hide(0);
    }
  })
})

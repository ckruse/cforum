/* -*- coding: utf-8 -*- */

/**
 * JS-Anweisungen für den Ausdruck von Postings im SelfHTML-Forum
 *
 * @version 0.1
 * @author M. Apsel
 * @author H. August <post@auge8472.de>
 **/


$(document).ready(function(){
  $('.forum-links nav ul').append(' <li><a href="" class="print">Beitrag drucken</a></li>');
  $('.forum-links .print').click(function( event ){
    $(this).parents('.thread-message').toggleClass('print');
    $('body').toggleClass('print-preview');
    if ($(this).parents('.thread-message').hasClass('print')){
      var i = 0, $list = '<hr class="printfootnotes"><ul class="printfootnoteurls"></ul>', $notes = '';
      $('.print .posting-content a:not(.mention)').each(function(){
        if(this.href != this.text && this.href != this.text+"/") {
          i++;
          $(this).after('<sup class="printfootnote">[L'+i+']</sup>');
          $notes += '<li><sup class="printfootnote">[L'+i+']: </sup> URL: '+this.href+'</li>';
        }
      });
      if (i > 0) {
        $('.print .posting-content').append($list);
        $('.printfootnoteurls').append($notes);
      }
      $(this).text('Druckansicht verlassen');
      window.print();
    } else {
      $('.printfootnotes, .printfootnoteurls, .printfootnote').remove();
      $(this).text('Beitrag drucken');
    }
    event.preventDefault();
  })
})

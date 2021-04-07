let scroll_buffer = [];
let scroll_dates = [];
let start = 0;

var checkScrollSpeed = (function(settings){
    settings = settings || {};

    let lastPos, newPos, timer, delta,
        delay = 250; //settings.delay || 10;

    //let start = new Date();

    function clear() {
        lastPos = null;
        delta = 0;
    }

    clear();

    return function(){
        newPos = window.scrollY;
        if ( lastPos != null ){ // && newPos < maxScroll
            delta = newPos -  lastPos;
        }
        lastPos = newPos;
        clearTimeout(timer);
        timer = setTimeout(clear, delay);
        return delta;
    };
})();


document.addEventListener('scroll', function() {
    start = new Date();
    let measurement = checkScrollSpeed();
    scroll_dates.push(start);
    scroll_buffer.push(measurement);
    console.log(scroll_dates);
    console.log(scroll_buffer);
    if (scroll_buffer.length >= 100){
      //console.log("Scroll buffer 100 long. Record and wipe");
      //console.log(scroll_buffer);
      let message = {type: 'log_scroll', data: {"scroll_dates" : scroll_dates, "scroll_buffer": scroll_buffer}};
      chrome.runtime.sendMessage(message);
      scroll_dates = [];
      scroll_buffer = [];
      //console.log(scroll_buffer);
    }
});
